module Greenhouse
  module Commands
    class Specs
      include Command
      command_summary "Run rspec for one or all of your projects"
      # TODO -q/--quiet argument
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
        results = Resources::Specs::Results.new
        Projects::projects.each do |project|
          results << Tasks::ProjectSpecs.perform(project).results
        end
        results.output
      end

      def run_project_specs
        Resources::Specs::Results.new([Tasks::ProjectSpecs.perform(@project).results]).output
      end

      def run
        @project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        @project.nil? ? run_all_specs : run_project_specs
      end

    end
  end
end
