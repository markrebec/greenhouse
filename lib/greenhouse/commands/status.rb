module Greenhouse
  module Commands
    class Status
      include Command
      summary "List projects and their current status"
      valid_argument Scripts::Argument.new("-g, --git", :summary => "Check git remotes to ensure you're status report is up-to-date on branch status, etc.")
      valid_argument Scripts::Argument.new("-v, --verbose", :summary => "Print out verbose information about branch and commit status")
      valid_argument Scripts::Argument.new("-r, --remote", :summary => "Include information about remote branches that are available to be checked out")
      valid_argument Scripts::Argument.new("--all", :summary => "Print status for all projects (default)")
      valid_argument Scripts::Argument.new("--apps", :summary => "Print status for all applications")
      valid_argument Scripts::Argument.new("--gems", :summary => "Print status for all gems")
      # TODO move engine to ForthRail
      #valid_argument Scripts::Argument.new("--engine", :summary => "Print status for the Forth Rail Engine")
      project_arguments *Projects::projects.map(&:to_arg)
      
      def self.usage
        puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} [<project>] #{valid_arguments.to_s}

Arguments:
#{valid_arguments.to_help}

Projects:
#{project_arguments.to_help}
USAGE
      end

      def run
        project.nil? ? ecosystem_status : project_status
      end

      def project
        Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
      end

      def with_git?
        arguments.map(&:key).include?("-g")
      end
      
      def remote?
        arguments.map(&:key).include?("-r")
      end

      def verbose?
        arguments.map(&:key).include?("-v")
      end

      def project_type
        arguments.map(&:key).include?("--apps") ? 'applications' : (arguments.map(&:key).include?("--gems") ? 'gems' : 'projects')
      end
      
      def ecosystem_status
        if Projects::send(project_type).empty?
          puts "No #{project_type} in your ecosystem."
          return
        end

        Projects::send(project_type).each do |project|
          Tasks::ProjectStatus.perform(project, with_git?, verbose?, remote?)
        end
      end

      def project_status
        Tasks::ProjectStatus.perform(project, with_git?, verbose?, remote?)
      end
    end
  end
end
