#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby

require 'fileutils'
require 'commander/import'
require 'nokogiri'
require 'rexml/document'
require 'yaml'

# TODO Refactor this, it's procedural & monolithic AF
module StarkUtils

  ARDUINO_LIB_DIR = ".arduino_lib"

  CODE_CARD_FILE = "code.xml"
  
  COURSE_MARKER_FILE = ".stark.yml"

  COURSE_NAME_REGEX = /\A[A-z|\s]+\Z/
  
  CHAPCARD_REGEX = /\A[0-9]{1,3}\s*-\s*\w[\w|\s]+\Z/ # used for both chapters and cards

  MAKEFILE = File.join("test", "Makefile")

  MAKEFILE_BACKUP = File.join("test", "Makefile.bak")

  CARD_SYMLINKS_DIR = ".links"

  RESOURCE_DIR = File.join(File.dirname(File.expand_path(__FILE__)), "..", "resources")

  ARDUINO_TEMPLATE = File.join(RESOURCE_DIR, "courses", "arduino", ".")

  ARDUINO_LIB_RESOURCE = File.join(RESOURCE_DIR, "courses", ARDUINO_LIB_DIR)
  
  COURSE_SCHEMA = File.join(RESOURCE_DIR, "maester.xsd")
  
  TEMPLATES_DIR = File.join(RESOURCE_DIR, "templates")


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

    unless valid_course_dir
      say_warning "This directory does not actually contain a chapter. Are you sure you made its parent with \"stark init\"? :-)"
      return
    end

    card_choice = do_gracefully { choose("What type of card do you want?", :Instruction, :Code, :Medium, :Question) }
    card_name = StarkUtils.get_necessary_argument(
                  [],
                  "Give your card a title (number, dash, title - for example: " +
                    "\"1 - Connect Your Arduino\") " +
                    "- it has to match that format!: ") { |card_name| foo = (card_name =~ CHAPCARD_REGEX) }

    card_template = File.join(TEMPLATES_DIR, card_choice.to_s.downcase.concat(".xml"))
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


  # Attempts to compile and test all the code to which code cards refer to, given
  # a directory that might contain a Stark Labs course.
  def StarkUtils.compile_and_test(args)
    dir = StarkUtils.get_necessary_argument(args, "Cool, but where's your course? :-) ")

    unless valid_course_dir?(dir)
      say_warning "This directory does not contain a Stark Labs course. Are you " +
                    "sure you made it with \"stark init\"? :-)"
      return
    end
    
    # Dispatch to platform-specific method
    platform = get_course_property(dir, "platform")
    case platform
    when "arduino"
      compile_and_test_arduino(dir)
    else
      # TODO Add other platforms later
      message_tail = platform ? "your platform isn't supported (yet?)!" : 
        "we couldn't detect your platform!"
      say_warning "We're sorry buddy but #{message_tail}"
      say_ok "Those platforms are supported:\n" +
        " 1. Arduino Uno"
    end
  end
    
    
  def StarkUtils.compile_and_test_arduino(dir)
    # Generate Makefile dynamically:
    # For every code card in the course, look whether both the test file and the
    # solution files exist. If they do, make a symlink to the card and generate the 
    # targets that will be added to the makefile.
    code_card_files = Dir.glob("#{dir}*/*/" + CODE_CARD_FILE)
    any_error = false
    tests = []
    targets = []
      
    # TODO: Filter out directories that don't match the expected format (CHAPCARD_REGEX)

    clear_symlinks(dir)

    code_card_files.each do |card|
      puts card
      make_symlink(dir, card)
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
      unless test && File.exist?(card.sub(CODE_CARD_FILE, test))
        say_error "Um, your test for #{card} doesn't seem to exist (read \"#{test}\")..." 
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
    makefile = File.join(dir, MAKEFILE)
    makefile_bak = File.join(dir, MAKEFILE_BACKUP)
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
  
  
  # If the parameter directory contains a course, objects are checked for validity 
  # against the platform's restrictions.
  def StarkUtils.validate_course(args)
    dir = StarkUtils.get_necessary_argument(args, "Cool, but where's your course? :-) ")

    unless valid_course_dir?(dir)
      say_warning "This directory does not contain a Stark Labs course. Are you " +
                    "sure you made it with \"stark init\"? :-)"
      return
    end
    
    course_doc = assemble_course(dir)
    puts "Assembled course:\n"
    puts "#{StarkUtils.pretty_print_xml(course_doc.to_xml)}\n\n"
    errors = validate_against_xsd(course_doc)
    if errors.empty?
      puts "Your course looks valid. You can publish it with 'stark push'!"
    else
      puts "You have #{errors.size} errors (format: '<line#> - <error>'):"
      errors.each { |error| puts "#{error.line + 1} - #{error.message}" }
    end
    
    errors.empty?
  end


  private # --------------------------------------------------------------------

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
  
  
  # Retrieves the value for the property of the course at the given directory (if
  # present). Returns nil if nothing was found.
  def StarkUtils.get_course_property(course_dir, property)
    YAML.load_file(File.join(course_dir, COURSE_MARKER_FILE))[property]
  end

  
  # Given a directory that contains a course, it clears all members of its symbolic
  # links directory.
  def StarkUtils.clear_symlinks(course_dir)
    FileUtils.rm_f(Dir.glob(File.join(course_dir, CARD_SYMLINKS_DIR, "*")))
  end

  
  # Given a directory that contains a course as well as the path of a card file,
  # it creates a symbolic link in the course's symbolic link directory that points
  # to the card directory. For example, if the card is at "1 - Ch1/1 - Card1",
  # .links/1_2 ->  is created.
  def StarkUtils.make_symlink(course_dir, card_file_path)
    card_dir = File.dirname(card_file_path)
    card_dir_name = File.basename(card_dir)
    chapter_dir_name = File.basename(File.dirname(card_dir))
    link_name = "#{strip_dir_number(chapter_dir_name)}_#{strip_dir_number(card_dir_name)}"
    FileUtils.ln_s(File.absolute_path(card_dir), File.join(course_dir, CARD_SYMLINKS_DIR, link_name))
  end
  

  # Given a directory name that begins with a number, it strips the number - returns
  # an empty string otherwise.
  def StarkUtils.strip_dir_number(dir)
    dir ? dir.match(/^(?<num>\d+)/) : ""
  end
  

  # Creates an XML document out of the course structure residing at the parameter directory.
  def StarkUtils.assemble_course(dir)
    doc = Nokogiri::XML(File.open(File.join(TEMPLATES_DIR, "course.xml")))
    course = doc.root
    course[:title] = File.basename(course[:title]) # get the title only

    chapters = Dir.glob("#{dir}*#{File::SEPARATOR}").
                   select{ |d| File.basename(d) =~ CHAPCARD_REGEX }

    chapters.each do |chapter|
      chapter_node = Nokogiri::XML::Node.new('chapter', course)
      chapter_node[:title] = chapter
      course.add_child(chapter_node)
      
      Dir.glob("#{chapter}*").each do |card_dir|
        card_file = Dir.glob "#{card_dir}#{File::SEPARATOR}*.xml"
        unless card_file.empty?
          chapter_node.add_child(Nokogiri::XML.parse(File.read(card_file.first)).root)
        end
      end
    end

    doc
  end
  
  
  # Validates the given XML document against the Stark Labs XSD schema.
  def StarkUtils.validate_against_xsd(doc)
    # Need to write out a temp file for accurate error reporting - Nokogiri gives out
    # messed up line numbers otherwise
    temp_validation_file = ".course.tmp"
    schema = Nokogiri::XML::Schema(File.read(COURSE_SCHEMA))
    File.write(temp_validation_file, doc.to_xml)
    errors = schema.validate(temp_validation_file)
    FileUtils.rm(temp_validation_file, :force => true)
    errors
  end
  
  
  # Given a string that contains an XML file content, it returns a formatted string
  # ("pretty-printed") using the default indentation (2 spaces) that also contains
  # line numbers at the beginning of each line.
  def StarkUtils.pretty_print_xml(xml_s)
    doc = REXML::Document.new(xml_s)
    formatter = REXML::Formatters::Pretty.new
    
    # Format with proper indentation & add line numbers at the beginning 
    # (better error reporting)
    formatter.compact = true
    formatter.write(doc.root, "").lines.map!.with_index {|line, i| "#{i + 1}> #{line}"}.join
  end

end