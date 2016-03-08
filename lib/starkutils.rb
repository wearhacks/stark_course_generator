#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby

module StarkUtils
 
    RESOURCE_DIR = File.join(File.dirname(File.expand_path(__FILE__)), '../resources')

    require 'fileutils'

    # Choose a bootstrapping method based on the platform.
    def StarkUtils.bootstrap_course(course_name, platform = "arduino")
        case platform
        when "arduino"
            bootstrap_arduino_course(course_name)
        else 
            # TODO Add other platforms later
            puts HighLine.color("We're sorry buddy but #{platform} is not supported (yet?)!", :yellow)
            puts "Those platforms are supported:"
            puts " [1] Arduino Uno"
        end
    end

    # Bootstrap a course for Arduino (default platform).
    def StarkUtils.bootstrap_arduino_course(course_name)
        puts "Creating #{course_name} based on the Arduino template..."
        proceed = Dir.exists?("#{course_name}") ? do_gracefully {
            agree("#{course_name} exists already there - creating a course " <<
                "with the same name will drop everything under there. " <<
                "Proceed? (yes/no)") 
        } : true
        return if !proceed
        FileUtils.mkdir "#{course_name}"
        FileUtils.cp_r (RESOURCE_DIR << "/courses/arduino/."), "#{course_name}"
    end


    # HighLine throws on either ^C or ^D during I/O (e.g. when calling ask).
    def StarkUtils.do_gracefully
        begin
            yield
        rescue Interrupt, EOFError
            puts
            exit
        end
    end

end
