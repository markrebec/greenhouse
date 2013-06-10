module Greenhouse
  module Tasks
    class ProjectStatus
      include Task
      include ProjectTask

      def perform(project, verbose=false)
        @project = project
        @project.repository.fetch if verbose && @project.exists?

        Inkjet.indent do
          puts "#{@project.title.cyan} (#{@project.type.capitalize})"
          Inkjet.indent do
            puts "#{@project.repository.remote}"
            puts "#{@project.exists? ? "Initialized".green : "Not Initialized".yellow}"
            puts "#{@project.configured? ? "Configured".green : "Not Configured".yellow}" if @project.exists? && @project.is_a?(::Greenhouse::Projects::Application)

            if @project.exists?
              if !verbose
                puts "Uncommitted Changes".yellow if @project.repository.changes?
                puts "Unpushed Branches".yellow if @project.repository.ahead?
                puts "Unpulled Branches".yellow if @project.repository.behind?
                puts "Diverged Branches".yellow if @project.repository.diverged?
              end

              if !@project.repository.changes? && !@project.repository.ahead? && @project.repository.up_to_date?
                puts "Up-to-date".green
              elsif verbose
                print_local_changes if @project.repository.changes?
                print_unpushed_branches if @project.repository.ahead?
                print_out_of_sync_branches if @project.repository.out_of_sync?
              end
              print_not_checked_out_branches if verbose && @project.repository.not_checked_out?
            end
          end
        end

      end
    end
  end
end
