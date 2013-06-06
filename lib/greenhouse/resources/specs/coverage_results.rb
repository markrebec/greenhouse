module Greenhouse
  module Resources
    module Specs
      class CoverageResults
        attr_accessor :project

        def initialize(project, results)
          @project = project
          @raw_results = results
        end

        def percentage_color(percentage)
          if percentage <= 40
            "\e[31m"
          elsif percentage <= 70
            "\e[33m"
          elsif percentage < 100
            "\e[36m"
          else
            "\e[32m"
          end
        end

        def to_summary
          "#{percentage_color(total_coverage)}#{"%.2f%% coverage" % total_coverage}\e[0m"
        end

        def to_result_string
          <<RESULT
    Coverage:
#{paths.map do |path|
  filename = path.split("#{project.path}/").last
  percentage = (lines[path] > 0 ? (hits[path].to_f/lines[path])*100 : 0).to_f
  "      #{percentage_color(percentage)}#{("%-70s %4.f%%" % [filename, percentage]).gsub(" ", ".")}\e[0m"
end.join("\n")}
      ============================================================================
      #{percentage_color(total_coverage)}#{"TOTAL COVERAGE: %.2f%%" % total_coverage}\e[0m

RESULT
        end

        def total_coverage
          (total_hits > 0 && total_lines > 0) ? ((total_hits.to_f / total_lines) * 100) : 0
        end

        def total_lines
          @total_lines ||= total_hits + total_misses
          #@total_lines ||= results.values.map do |coverage_array|
          #  coverage_array.compact.reduce(0){|m, it| it>0 ? m+1 : m } + coverage_array.compact.reduce(0){|m, it| it==0 ? m+1 : m }
          #end.inject(:+)
        end

        def total_hits
          @total_hits ||= hits.values.inject(:+)
          #results.values.map do |coverage_array|
          #  coverage_array.compact.reduce(0){|m, it| it>0 ? m+1 : m }
          #end.inject(:+)
        end

        def total_misses
          @total_misses = misses.values.inject(:+)
          #results.values.map do |coverage_array|
          #  coverage_array.compact.reduce(0){|m, it| it==0 ? m+1 : m }
          #end.inject(:+)
        end

        def paths
          @paths ||= results.keys
        end

        def lines
          @lines ||= Hash[paths.map do |path|
            [path, hits[path] + misses[path]]
          end]
        end

        def hits
          @hits ||= Hash[results.map do |path,coverage_array|
            [path, coverage_array.compact.reduce(0){|m, it| it>0 ? m+1 : m }]
          end]
        end
        
        def misses
          @misses ||= Hash[results.map do |path,coverage_array|
            [path, coverage_array.compact.reduce(0){|m, it| it==0 ? m+1 : m }]
          end]
        end

        def results
          @results ||= @raw_results.select { |key,value| key.start_with?(project.path) && !key.match(/#{project.path}\/spec/) }
        end
      end
    end
  end
end
