module Greenhouse
  module Commands
    class Push
      include Command
      command_summary "Push local branches for all projects to their git remotes"
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

      def push_all
        if Projects.projects.empty?
          puts "No projects defined."
          return
        end

        Projects.projects.each do |project|
          Tasks::PushProject.perform(project)
        end
      end

      def push_project(project)
        unless project.exists?
          puts "Project #{project.title.cyan} does not exist. Try initializing it with `greenhouse init`"
          return
        end

        Tasks::PushProject.perform(project)
      end

      def run
        project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        project.nil? ? push_all : push_project(project)
      end
    end
  end
end
