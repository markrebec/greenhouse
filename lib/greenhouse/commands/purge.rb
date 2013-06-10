module Greenhouse
  module Commands
    class Purge
      include ::Greenhouse::Commands::Command
      command_summary "Purge project directories from your ecosystem allowing you to start from scratch"
      valid_argument Scripts::Argument.new("-a --all", :summary => "Remove your ecosystem configuration files in addition to project directories (will NOT prompt when combined with -f)")
      valid_argument Scripts::Argument.new(["-f", "--force"], :summary => "Force the purge, will still prompt if you have local changes or unpushed local branches")
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

      def clean?
        return false if Projects::projects_file.exists?
        return false if Projects::ignore_file.exists?
        return false if Projects::procfile.exists?
        return false if Projects::projects.any?(&:exists?)
        true
      end

      def force?
        arguments.map(&:key).include?("-f")
      end

      def purge_all?
        arguments.map(&:key).include?("-a")
      end
      
      def run
        app = Projects::projects.select { |project| arguments.map(&:key).include?(project.name) }.first
        if app.nil?
          if clean?
            puts "Nothing to do."
            return
          end
        
          purge
        else
          Tasks::PurgeProject.perform(app, force?)
        end

        puts "Done".yellow
        return
      end

      def purge
        Projects.projects.each do |project|
          Tasks::PurgeProject.perform(project, force?)
        end

        Tasks::RemoveGreenhouseFiles.perform(force?) if purge_all?
      end
    
    end
  end
end
