#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby

require 'fileutils'
require 'commander/import'
require 'nokogiri'

# TODO Refactor this, it's procedural & monolithic AF
module StarkUtils

  ARDUINO_LIB_DIR = ".arduino_lib"

  CODE_CARD_FILE = "code.xml"
  
  COURSE_MARKER_FILE = ".stark.yml"

  COURSE_NAME_REGEX = /\A[A-z|\s]+\Z/

  CHAPCARD_REGEX = /\A[0-9]{1,3}\s*-\s*\w[\w|\s]+\Z/ # used for both chapters and cards

  MAKEFILE_FILE = File.join("test", "Makefile")

  MAKEFILE_FILE_BACKUP = File.join("test", ".Makefile.bak")

  RESOURCE_DIR = File.join(File.dirname(File.expand_path(__FILE__)), '../resources')

  ARDUINO_TEMPLATE = File.join(RESOURCE_DIR, "courses", "arduino", ".")

  ARDUINO_LIB_RESOURCE = File.join(RESOURCE_DIR, "courses", ARDUINO_LIB_DIR)


  # Dispatches to a platform-specific bootstrapping method.
  def StarkUtils.bootstrap_course(args = [])
    course_name = StarkUtils.get_necessary_argument(
                    args,
                    "Give your course a name (must only contain letters " +
                      "or whitespace - e.g. \"Blink\"): ") { |name| name =~ COURSE_NAME_REGEX }
    platform = (args.size > 1) ? args[1] : "arduino"
    
    case platform
    when "arduino"
      bootstrap_arduino_course(course_name)
    else
      # TODO Add other platforms later
      say_warning "We're sorry buddy but #{platform} is not supported (yet?)!"
      say_ok "Those platforms are supported:\n" +
        " 1. Arduino Uno"
    end
  end


  # Leads the user to the creation of a card for the given chapter through Q&A.
  def StarkUtils.add_card(args)
    chapter_dir = StarkUtils.get_necessary_argument(args, "Provide the path to one of your course's chapters: ")
    valid_course_dir = StarkUtils.valid_course_dir?(chapter_dir, [".."])
    if !valid_course_dir
      say_warning "This directory does not actually contain a chapter. Are you sure you made its parent with \"stark init\"? :-)"
      return
    end

    card_choice = do_gracefully { choose("What type of card do you want?", :Instruction, :Code, :Medium, :Question) }
    card_name = StarkUtils.get_necessary_argument(
                  [],
                  "Give your card a title (number, dash, title - for example: " +
                    "\"1 - Connect Your Arduino\") " +
                    "- it has to match that format!: ") { |card_name| foo = (card_name =~ CHAPCARD_REGEX) }

    card_template = File.join(RESOURCE_DIR, "cards", card_choice.to_s.downcase.concat(".xml"))
    card_dir = File.join(chapter_dir, card_name)

    begin
      Dir.mkdir(card_dir)
      FileUtils.cp(card_template, card_dir)
      say_ok "Done! Your card is at #{card_dir} ."
    rescue SystemCallError
      FileUtils.rm_r(card_dir) # Cleanup
      say_error "Creating the card failed: " + $!
    end
  end

  
  def StarkUtils.compile_and_test(args)
    dir = StarkUtils.get_necessary_argument( args, "Cool, but where's your course? :-) ")

    unless valid_course_dir?(dir)
      say_warning "This directory does not contain a Stark Labs course. Are you " +
                    "sure you made it with \"stark init\"? :-)"
      return
    end
    
    # TODO: This is Arduino-specific - move to a separate method
    # if contains_arduino_course?(dir)
    #  puts "Move this to another method you dumbass"
    # end

    # Generate Makefile dynamically:
    # For every code card in the course, look whether both the test file and the
    # solution files exist. If they do, make a symlink to the card and generate the 
    # targets that will be added to the makefile.
    
    code_cards = Dir.glob("#{dir}/*/*/" + CODE_CARD_FILE)
    any_error = false
    tests = []
    targets = []

    code_cards.each do |card|
      doc = Nokogiri::XML(File.open(card))
      # Can't seem to find a way to do this in 1 go - maybe it's XPath 2.0 only
      solution = doc.xpath("//code/@solution").first
      test = doc.xpath("//code/@test").first
      
      # Do some checks
      unless solution && File.exist?(card.sub(CODE_CARD_FILE, solution))
        say_error "Um, your template solution for #{card} doesn't seem to exist (read \"#{solution}\")..." 
        any_error = true unless any_error 
        next
      end
      unless solution && File.exist?(card.sub(CODE_CARD_FILE, solution))
        say_error "Um, your test for #{card} doesn't seem to exist (read \"#{solution}\")..." 
        any_error = true unless any_error 
        next
      end

      solution_file = solution.value.match(/(?<filename>.*)\./)
      solution_file = solution_file[:filename] if solution_file
      solution_file ||= solution.value # oh well, someone doesn't like extensions
      test_file = test.value.match(/(?<filename>.*)\./)
      test_file = test_file[:filename] if test_file
      test_file ||= test.value
    
      # TODO Make the symlinks programmatically, this only works because I made 
      #      them manually
      tests.push(test_file)

      targets.push("#{test_file}.o : $(COURSE_HOME)/.links/1_2/#{test} " +
        "$(COURSE_HOME)/.links/1_2/#{solution} $(GTEST_HEADERS) " +
        "$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $(COURSE_HOME)/.links/1_2/#{test}")
      
      targets.push("#{test_file} : $(COURSE_HOME)/.links/1_2/#{test_file}.o " +
        "gmock_main.a arduino_mock_all.a\n" +
        "\t$(CXX) $(CPPFLAGS) $(CXXFLAGS) -lpthread $^ -o $@")
    end
    
    # Don't go any further 
    if any_error
      say_error "There was at least one error which ensures that your code will not "
        "compile and run (see log above). Fix any errors and try again."
      return
    end
    
    # Back up the template, generate the makefile, run the targets and copy the
    # template back.
    makefile = File.join(dir, MAKEFILE_FILE)
    makefile_bak = File.join(dir, MAKEFILE_FILE_BACKUP)
    FileUtils.cp(makefile, makefile_bak)
   
    content = File.read(makefile) 
    content = content.gsub(/^(COURSE_HOME =.*)$/, "COURSE_HOME = #{dir.gsub(/\/$/, "")}")
    content = content.gsub(/^(TESTS =.*)$/, "TESTS = #{tests.join(" ")}")
    content << targets.join("\n\n")
    File.open(makefile, "w") { |file| file << content }

    system("make -f #{makefile} test") # Any better way to do this?
    say_ok "\nDone compiling/running tests. Cleaning up now...\n"
    system("make -f #{makefile} clean")
    
    FileUtils.mv(makefile_bak, makefile)

    say_ok "Done!"
  end


  # If the given directory contains a Stark Labs course, it will pretty-print
  # its contents in the form of a directory tree.
  def StarkUtils.list_course_contents(args)
    dir = StarkUtils.get_necessary_argument(args, "Cool, but where's your course? :-) ")

    if valid_course_dir?(dir)
      print_tree(dir)
    else
      say_warning "This directory does not contain a Stark Labs course. Are you " +
        "sure you made it with \"stark init\"? :-)"
    end
  end


  private

  # Gets a non-empty, necessary command argument from the user if the given arguments
  # are non-empty. A block can be supplied optionally to perform input validation
  # (e.g. to match against a RegEx).
  # If you do supply a block, you have to make sure that the args type matches
  # the type of the block's parameters.
  def StarkUtils.get_necessary_argument(args, ask_message)
    param = args.first
    while (block_given? ? !Proc.new.call(param) : false) || (!param || param.empty?) do
      param = do_gracefully { ask(ask_message) }
    end
    param
  end


  # HighLine throws on either ^C or ^D during I/O (e.g. "ask") - this will catch those.
  def StarkUtils.do_gracefully
    begin
      yield
    rescue Interrupt, EOFError
      puts
      exit
    end
  end


  # Bootstrap a course for Arduino (default platform).
  def StarkUtils.bootstrap_arduino_course(course_name)
    proceed = Dir.exists?("#{course_name}") ? 
                (do_gracefully do
                  agree("#{course_name} exists already there - creating " +
                    "a course with the same name will drop everything " +
                    "under there. Proceed? (yes/no) ")
                end) : true
    return if !proceed

    puts "Creating #{course_name} based on the Arduino template..."
    FileUtils.rm_rf "#{course_name}"
    FileUtils.mkdir "#{course_name}"
    FileUtils.cp_r(ARDUINO_TEMPLATE, "#{course_name}")
    # copy the test libs if they don't exist (so that other courses can use them too)
    FileUtils.cp_r(ARDUINO_LIB_RESOURCE, ".") unless Dir.exists? ARDUINO_LIB_DIR

    say_ok "Done!"
  end


  # Print a course's structure with appropriate indentation.
  # Snippet taken from http://compsci.ca/v3/viewtopic.php?t=13034 (so 2006, wow)
  def StarkUtils.print_tree(dir = ".", nesting = 0)
    Dir.foreach(dir) do |entry|
      next if entry =~ /^\.{1,2}/   # Ignore ".", "..", or hidden files
      puts "|   " * nesting + "|-- #{entry}"
      if File.stat(d = "#{dir}#{File::SEPARATOR}#{entry}").directory?
        print_tree(d, nesting + 1)
      end
    end
  end


  # Checks if the directory at the given path contains a Stark Labs course.
  # You can optionally provide levels that should be skipped. For example:
  # valid_course_dir?("some/dir", ["..", "..",]) will lead to checking if
  # some/dir/../.. is a valid course directory.
  def StarkUtils.valid_course_dir?(path, levels = [])
    start = File.join(path)
    levels.each { |l| start = File.join(start, l) }
    File.exist?(File.join(start, COURSE_MARKER_FILE))
  end

end