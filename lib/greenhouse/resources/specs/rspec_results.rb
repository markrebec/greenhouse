require 'rspec'

module Greenhouse
  module Resources
    module Specs
      class RspecExample
        attr_reader :description, :full_description, :status, :file_path, :line_number
        
        def initialize(example)
          @description = example['description']
          @full_description = example['full_description']
          @status = example['status']
          @file_path = example['file_path']
          @line_number = example['line_number']
        end

        def to_s
          "#{file_path}:#{line_number} # #{full_description}"
        end

        def to_result_string; end
      end

      class PassingExample < RspecExample
        def to_s
          "\e[32m#{file_path}:#{line_number}\e[0m # #{full_description}"
        end

        def to_result_string; end
      end

      class PendingExample < RspecExample
        def to_s
          "\e[33m#{file_path}:#{line_number}\e[0m # #{full_description}"
        end

        def to_result_string
          <<RESULT
      \e[33m#{full_description}\e[0m
        \e[34m# Not Yet Implemented\e[0m
        \e[34m# #{file_path}:#{line_number}\e[0m
RESULT
        end
      end

      class FailedExample < RspecExample
        attr_reader :exception

        def initialize(example)
          super
          @exception = example['exception']['class'].constantize.new(example['exception']['message'])
          @exception.set_backtrace example['exception']['backtrace']
        end
        
        def to_s
          "\e[31m#{file_path}:#{line_number}\e[0m # #{full_description}"
        end

        def to_result_string
          <<RESULT
      #{1.to_s}) #{full_description}
         \e[31mFailure/Error: #{relevant_line}
         #{message.gsub("\n", "\n         ")}\e[0m
         \e[34m# #{file_path}:#{relevant_line_number}:#{relevant_context}\e[0m
RESULT
        end

        def to_summary
          <<SUMMARY
      \e[31mrspec #{file_path}:#{line_number}\e[0m \e[34m# #{full_description}\e[0m
SUMMARY
        end

        def message
          exception.message
        end

        def backtrace
          exception.backtrace
        end

        def regex_path
          file_path.gsub(/\A\.\//,'').gsub(/\//, '\/')
        end

        def relevant_trace
          backtrace.select { |line| line.match(/#{regex_path}/) }.first
        end

        def full_path
          relevant_trace.split(":")[0]
        end

        def relevant_line_number
          relevant_trace.split(":")[1].to_i
        end

        def relevant_line
          File.read(full_path).split("\n")[relevant_line_number-1].strip
        end

        def relevant_context
          relevant_trace.split(":in ").last
        end
      end

      class RspecExamples < Array
        def to_result_string; end
      end

      class PassingExamples < RspecExamples
        def to_result_string; end
      end

      class PendingExamples < RspecExamples
        def to_result_string
          <<RESULTS
    Pending:
#{map(&:to_result_string).join}

RESULTS
        end
      end

      class FailedExamples < RspecExamples
        def to_result_string
          <<RESULTS
    Failures:
#{map(&:to_result_string).join}

RESULTS
        end
        
        def to_summary
          <<SUMMARY
    Failed Examples:
#{map(&:to_summary).join}

SUMMARY
        end
      end

      class RspecResults < Hash
        def []=(key,val)
          super(key.to_s,val)
        end

        def [](key)
          super(key.to_s)
        end

        def examples
          return RspecExamples.new unless keys.include?('examples')
          RspecExamples.new(self['examples'].map do |ex|
            case ex['status']
            when 'passed'
              PassingExample.new(ex)
            when 'pending'
              PendingExample.new(ex)
            when 'failed'
              FailedExample.new(ex)
            end
          end)
        end

        def passed
          PassingExamples.new examples.select { |ex| ex.status == 'passed' }
        end

        def pending
          PendingExamples.new examples.select { |ex| ex.status == 'pending' }
        end

        def failed
          FailedExamples.new examples.select { |ex| ex.status == 'failed' }
        end

        def duration
          self['summary']['duration'].to_f.round(2) if keys.include?('summary')
        end

        def summary_text_color
          if failed.count > 0
            "\e[31m"
          elsif pending.count > 0
            "\e[33m"
          elsif examples.count > 0
            "\e[32m"
          end
        end

        def to_summary
          "  #{summary_text_color}#{summary_text}\e[0m"
        end
        
        def summary_text
          self['summary_line']
        end
      end
    end
  end
end
