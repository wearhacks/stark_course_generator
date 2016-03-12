#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby

require 'fileutils'
require 'commander/import'

# TODO Refactor this, it's monolithic AF
module StarkUtils

  COURSE_MARKER_FILE = ".stark.yml"

  COURSE_NAME_REGEX = /\A[A-z|\s]+\Z/

  CHAPCARD_REGEX = /\A[0-9]{1,3}\s*-\s*\w[\w|\s]+\Z/ # used for both chapters and cards

  RESOURCE_DIR = File.join(File.dirname(File.expand_path(__FILE__)), '../resources')


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


  # If the given directory contains a Stark Labs course, it will pretty-print
  # its contents in the form of a directory tree.
  def StarkUtils.list_course_contents(args)
    dir = StarkUtils.get_necessary_argument( args, "Cool, but where's your course? :-) ")

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
                do_gracefully do
                  agree("#{course_name} exists already there - creating " +
                    "a course with the same name will drop everything " +
                    "under there. Proceed? (yes/no) ")
                end : true
    return if !proceed

    puts "Creating #{course_name} based on the Arduino template..."
    FileUtils.rm_rf "#{course_name}"
    FileUtils.mkdir "#{course_name}"
    arduino_template = File.join(RESOURCE_DIR, "courses", "arduino", ".")
    FileUtils.cp_r(arduino_template, "#{course_name}")
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