module Greenhouse
  module Commands
    class Sync
      include Command
      command_summary "Sync all projects with their git remotes"
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

      def sync_all
        if Projects.projects.empty?
          puts "No projects defined."
          return
        end

        Projects.projects.each do |project|
          Tasks::SyncProject.perform(project)
        end
        Tasks::GenerateProcfile.perform
      end

      def sync_project(project)
        Tasks::SyncProject.perform(project)
        Tasks::GenerateProcfile.perform if project.type == 'application'
      end

      def run
        project = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        project.nil? ? sync_all : sync_project(project)
      end
    end
  end
end
