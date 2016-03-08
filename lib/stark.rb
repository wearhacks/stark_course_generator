#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby
# require "stark/version"

module Stark

    require 'rubygems'
    require 'commander'
    require 'fileutils'
    require_relative 'starkutils'

    class Stark
        include Commander::Methods
        include StarkUtils

        def run
            program :name, "Stark Labs Course Generator"
            program :version, "0.0.1"
            program :description, "This is the course generator for the Stark Labs platform. " << 
                "The full documentation is available at " <<
                "https://github.com/wearhacks/stark_course_generator/edit/master/README.md ."

            command :init do |c|
                c.syntax = 'stark init <course_name> <platform>[default=arduino]'
                c.summary = 'Bootstraps a course with the given name for the target platform.'
                c.description = 'Bootstraps a course with the given name for the target platform.'
                c.example 'Creates a course for the target platform (default: Arduino).', 'init Blinky'
                c.action do |args, options|
                    course_name = args.first
                    while !course_name || course_name.empty? do
                        course_name = StarkUtils.do_gracefully { ask("Give your course a name: ") }
                    end
                    platform = args.length <= 1 ? "arduino" : args[1]
                    StarkUtils.bootstrap_course(course_name, platform)
                    say_ok "Done!"
                end
            end

            command :add do |c|
                c.syntax = 'stark add [options]'
                c.summary = ''
                c.description = ''
                c.example 'description', 'command example'
                c.option '--some-switch', 'Some switch that does something'
                c.action do |args, options|
                    # Do something or c.when_called stark::Commands::Add
                end
            end

            command :list do |c|
                c.syntax = 'stark list [options]'
                c.summary = ''
                c.description = ''
                c.example 'description', 'command example'
                c.option '--some-switch', 'Some switch that does something'
                c.action do |args, options|
                    # Do something or c.when_called stark::Commands::List
                end
            end

            command :test do |c|
                c.syntax = 'stark test [options]'
                c.summary = ''
                c.description = ''
                c.example 'description', 'command example'
                c.option '--some-switch', 'Some switch that does something'
                c.action do |args, options|
                    # Do something or c.when_called stark::Commands::Test
                end
            end

            command :validate do |c|
                c.syntax = 'stark validate [options]'
                c.summary = ''
                c.description = ''
                c.example 'description', 'command example'
                c.option '--some-switch', 'Some switch that does something'
                c.action do |args, options|
                    # Do something or c.when_called stark::Commands::Validate
                end
            end

            command :push do |c|
                c.syntax = 'stark push [options]'
                c.summary = ''
                c.description = ''
                c.example 'description', 'command example'
                c.option '--some-switch', 'Some switch that does something'
                c.action do |args, options|
                     Do something or c.when_called stark::Commands::Push
                end
            end

            default_command :help

            run!
        end
    end

end

Stark::Stark.new.run if $0 == __FILE__

