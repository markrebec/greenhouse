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
        results.each do |result|
          next if result[:rspec].nil?
          next unless result[:rspec].pending.count > 0 || result[:rspec].failed.count > 0
          
          puts "  \e[36m#{result[:project].title}\e[0m"

          puts result[:rspec].pending.to_result_string if result[:rspec].pending.count > 0
          
          puts result[:rspec].failed.to_result_string if result[:rspec].failed.count > 0


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
        results.each do |result|
          next if result[:rspec].nil?
          
          puts "  \e[36m#{result[:project].title}\e[0m finished in #{result[:rspec].duration} seconds"
          
          print result[:rspec].to_summary

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
          puts
          
          puts result[:rspec].failed.to_summary if result[:rspec].failed.count > 0
        end
      end

    end
  end
end
