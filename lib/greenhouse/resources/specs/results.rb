require 'json'

module Greenhouse
  module Resources
    module Specs
      class Result
        attr_accessor :project, :rspec, :coverage

        def initialize(project, rspec_file, coverage_file)
          @project = project
          @rspec_file = rspec_file
          @coverage_file = coverage_file

          @rspec = (rspec_results.empty? ? nil : RspecResults[JSON.parse(rspec_results).to_a])
          @coverage = (File.exists?(@coverage_file) ? CoverageResults.new(@project, YAML.load_file(@coverage_file)) : nil)
        end

        private

        def rspec_results
          File.exists?(@rspec_file) ? File.read(@rspec_file) : ''
        end
      end

      class Results < Array
        def output
          print_details
          print_summary
        end

        def print_details
          each do |result|
            next if result.rspec.nil?
            next unless result.rspec.pending.count > 0 || result.rspec.failed.count > 0 || !result.coverage.nil?
            
            puts "  \e[36m#{result.project.title}\e[0m"
            puts result.rspec.pending.to_result_string if result.rspec.pending.count > 0
            puts result.rspec.failed.to_result_string.chomp if result.rspec.failed.count > 0

            puts result.coverage.to_result_string unless result.coverage.nil?
          end
        end

        def print_summary
          each do |result|
            next if result.rspec.nil?
            
            puts "  \e[36m#{result.project.title}\e[0m finished in #{result.rspec.duration} seconds"
            
            puts "#{result.rspec.to_summary} - #{result.coverage.nil? ? "no coverage" : result.coverage.to_summary}"
            puts
            
            puts result.rspec.failed.to_summary if result.rspec.failed.count > 0
          end
        end
      end
    end
  end
end
