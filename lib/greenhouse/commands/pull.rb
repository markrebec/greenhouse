module Greenhouse
  module Commands
    class Pull
      include Command
      command_summary "Pull and merge remote branches for all projects"
      project_arguments *Projects::projects.map(&:to_arg)
      
      class << self
        def usage
          puts <<USAGE
usage: #{::Greenhouse::CLI.command_name} #{command_name} [<project>] #{valid_arguments.to_s}

Projects:
#{project_arguments.to_help}
USAGE
        end
      end

      def pull_all
        if Projects.projects.empty?
          puts "No projects defined."
          return
        end

        Projects.projects.each do |project|
          Tasks::PullProject.perform(project)
        end
      end

      def pull_project(project)
        unless project.exists?
          puts "Project #{project.title.cyan} does not exist. Try initializing it with `greenhouse init`"
          return
        end

        Tasks::PullProject.perform(project)
      end

      def run
        project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        project.nil? ? pull_all : pull_project(project)
      end
    end
  end
end
