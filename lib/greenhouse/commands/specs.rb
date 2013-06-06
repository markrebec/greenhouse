module Greenhouse
  module Commands
    class Specs
      include Command
      command_summary "Run rspec for one or all of your projects"
      # TODO arguments to prompt/review after each project
      project_arguments *Projects::projects.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} <#{valid_arguments.map(&:key).join(", ")}> [<project>]

Arguments:
#{valid_arguments.to_help}

Projects:
#{project_arguments.to_help}
USAGE
        end
      end

      def run_all_specs
        results = []
        Projects::projects.each do |project|
          results << Tasks::ProjectSpecs.perform(project).results
        end
        print_results(*results)
      end

      def run_project_specs
        print_results(Tasks::ProjectSpecs.perform(@project).results)
      end

      def run
        @project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        @project.nil? ? run_all_specs : run_project_specs
      end

      def print_results(*results)
        puts
        puts "Results:"
        results.each do |result|
          next if result[:rspec].nil?
          next unless result[:rspec]['summary']['pending_count'] > 0 || result[:rspec]['summary']['failure_count'] > 0
          puts
          puts "  \e[36m#{result[:project].title}\e[0m"

          if result[:rspec]['summary']['pending_count'] > 0
            puts "    Pending:"
            result[:rspec]['examples'].select { |ex| ex['status'] == 'pending' }.each do |pending|
              puts "      \e[33m#{pending['full_description']}\e[0m"
              puts "        \e[34m# Not Yet Implemented\e[0m"
              puts "        \e[34m# #{pending['file_path']}:#{pending['line_number']}\e[0m"
            end
            puts
          end


          if result[:rspec]['summary']['failure_count'] > 0
            puts "    Failures:"
            result[:rspec]['examples'].select { |ex| ex['status'] == 'failed' }.each_with_index do |failed,f|
              puts "      #{f+1}) #{failed['full_description']}"
              line_no = failed['exception']['backtrace'].select { |line| line.match(/#{failed['file_path'].gsub(/\A\.\//, '').gsub(/\//, '\/')}/) }.first.split(":")[1].to_i
              puts "         \e[31mFailure/Error: #{File.read("#{result[:project].path}/#{failed['file_path']}").split("\n")[line_no - 1].lstrip} \n           #{failed['exception']['message'].split("\n").join("\n      ")}\e[0m"
              puts "         \e[34m# #{failed['file_path']}:#{line_no}:#{failed['exception']['backtrace'].select { |line| line.match(/#{failed['file_path'].gsub(/\A\.\//, '').gsub(/\//, '\/')}/) }.first.split(":").last}\e[0m"
            end
            puts
          end
          
          unless result[:coverage].nil?
            puts
            puts "    Coverage:"
            total_lines = 0
            total_hits = 0
            result[:coverage].select { |key,value| key.start_with?(result[:project].path.to_s) }.each do |path, coverage_array|
              hits = coverage_array.compact.reduce(0){|m, it| it>0 ? m+1 : m }
              misses = coverage_array.compact.reduce(0){|m, it| it==0 ? m+1 : m }
              lines = hits+misses
            
              total_lines += lines
              total_hits += hits
            
              filename = path.split(result[:project].path+"/")[1]
              percentage = lines>0 ? (hits.to_f/lines)*100 : 0.0

              if percentage <= 40
                print "      \e[31m"
              elsif percentage <= 70
                print "      \e[33m"
              elsif percentage <= 99
                print "      "
              else
                print "      \e[32m"
              end
              puts "#{("%-70s %4.f%%" % [filename, percentage]).gsub(" ", ".")}\e[0m"
            end
          
            puts "      ============================================================================\n"
            if total_coverage(total_hits, total_lines) <= 40
              print "      \e[31m"
            elsif total_coverage(total_hits, total_lines) <= 70
              print "      \e[33m"
            elsif total_coverage(total_hits, total_lines) <= 99
              print "      "
            else
              print "      \e[32m"
            end
            puts "#{"TOTAL COVERAGE: %.2f%%" % total_coverage(total_hits, total_lines)}\e[0m"
            puts
          end
        end

        print_summaries(*results)
      end

      def total_coverage(total_hits, total_lines)
        (total_hits > 0 && total_lines > 0) ? ((total_hits.to_f/total_lines)*100) : 0
      end

      def print_summaries(*results)
        puts
        puts "Summary:"
        results.each do |result|
          next if result[:rspec].nil?
          
          puts "  \e[36m#{result[:project].title}\e[0m finished in #{result[:rspec]['summary']['duration'].to_f.round(2)} seconds"
          
          if result[:rspec]['summary']['failure_count'] > 0
            print "    \e[31m"
          elsif result[:rspec]['summary']['pending_count'] > 0
            print "    \e[33m"
          elsif result[:rspec]['summary']['example_count'] > 0
            print "    \e[32m"
          else
            print "    "
          end
          print "#{result[:rspec]['summary_line']}\e[0m"
          
          if result[:coverage].nil?
            puts
          else
            total_lines = 0
            total_hits = 0
            result[:coverage].select { |key,value| key.start_with?(result[:project].path.to_s) }.each do |path, coverage_array|
              hits = coverage_array.compact.reduce(0){|m, it| it>0 ? m+1 : m }
              misses = coverage_array.compact.reduce(0){|m, it| it==0 ? m+1 : m }
              lines = hits+misses
            
              total_lines += lines
              total_hits += hits
            end
          
            if total_coverage(total_hits, total_lines) <= 40
              print " - \e[31m"
            elsif total_coverage(total_hits, total_lines) <= 70
              print " - \e[33m"
            elsif total_coverage(total_hits, total_lines) <= 99
              print " - "
            else
              print " - \e[32m"
            end
            puts "#{"%.2f%% coverage" % total_coverage(total_hits, total_lines)}\e[0m"
          end
          
          if result[:rspec]['summary']['failure_count'] > 0
            puts
            puts "    Failed Examples:"
            result[:rspec]['examples'].select { |ex| ex['status'] == 'failed' }.each_with_index do |failed,f|
              puts "      \e[31mrspec #{failed['file_path']}:#{failed['line_number']}\e[0m \e[34m# #{failed['full_description']}\e[0m"
            end
          end
          
          puts
        end
      end

    end
  end
end
