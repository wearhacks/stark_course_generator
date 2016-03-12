#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby
# require "stark/version"

require 'rubygems'
require 'commander'
require 'fileutils'

module Stark

  require_relative 'starkutils'

  class Stark
    include Commander::Methods
    include StarkUtils

    def run
      program :name, "Stark Labs Course Generator"
      program :version, "0.0.1"
      program :description, "This is the course generator for the Stark Labs platform. " <<
      "The full documentation is available at " <<
      "https://github.com/wearhacks/stark_course_generator/wiki."

      command :init do |c|
        c.syntax = 'stark init <course_name> <platform>[default=arduino]'
        c.summary = 'Bootstraps a course with the given name for the target platform.'
        c.description = 'Bootstraps a course with the given name for the target platform.'
        c.example 'Creates a course for the target platform (default: Arduino).', 'stark init Blinky'
        c.action do |args, options|
          StarkUtils.bootstrap_course(args)
        end
      end

      command :add do |c|
        c.syntax = 'stark add <path/to/course/root>'
        c.summary = 'Leads to the creation of a card in a Q&A fashion.'
        c.description = 'Leads to the creation of a card in a Q&A fashion.'
        c.example 'Adds an instruction card to the 1st chapter of Blink:', %q{stark add \"Blink/1 - Introduction To Arduino Programming\"
        What type of card do you want?
        1. Instruction
        2. Code
        3. Medium
        4. Question
        ?  1
        Give your card a title (number, dash, title - for example: "1 - Connect Your Arduino") - it has to match that format!: 5 - Another Card
        Done! Your card is at Blink/1 - Introduction To Arduino Programming/5 - Another Card ...:w
        }
        c.action do |args, options|
          StarkUtils.add_card(args)
        end
      end

      command :list do |c|
        c.syntax = 'stark list <path/to/course/root>'
        c.summary = 'Pretty-prints the structure of the course (chapters & cards).'
        c.description = 'Pretty-prints the structure of the course (chapters & cards).'
        c.example 'Pretty-prints the structure of Blink:', %q{stark list Blink
          |-- 1 - Introduction To Arduino Programming
          |   |-- 1 - Connect Your Arduino
          |   |   |-- instruction.xml
          |   |-- 2 - Make Your Arduino Blink!
          |   |   |-- blink_solution.ino
          |   |   |-- blink_template.ino
          |   |   |-- blink_test.cc
          |   |   |-- code.xml
          |   |-- 3 - Connection Demonstration
          |   |   |-- medium.xml
          |   |-- 4 - Check Your Connectivity
          |   |   |-- question.xml
          |-- media
          |   |-- arduino-blink.gif
          |-- test
          |   |-- Makefile
        }
        c.action do |args, options|
          StarkUtils.list_course_contents(args)
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

