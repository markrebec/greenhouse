module Greenhouse
  module Commands
    class Status
      include Command
      command_summary "List projects and their current status"
      valid_arguments Scripts::Argument.new("-v, --verbose", :summary => "Print out detailed information about project status (local changes, ahead/behind/diverged branches, etc.)")
      project_arguments *Projects::projects.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} [<project>] #{valid_arguments.to_s}

Arguments:
#{valid_arguments.to_help}

Projects:
#{project_arguments.to_help}
USAGE
        end
      end

      def verbose
        arguments.map(&:key).include?("-v")
      end
      
      def ecosystem_status
        if Projects::projects.empty?
          puts "No projects configured."
          return
        end

        puts "The following projects are configured in your ecosystem: "
        Projects::projects.each do |project|
          puts
          Tasks::ProjectStatus.perform(project, verbose)
        end
      end

      def project_status(project)
        Tasks::ProjectStatus.perform(project, verbose)
      end

      def run
        project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        project.nil? ? ecosystem_status : project_status(project)
      end
    end
  end
end
