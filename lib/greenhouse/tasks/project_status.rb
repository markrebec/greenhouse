module Greenhouse
  module Tasks
    class ProjectStatus
      include Task
      include ProjectTask

      def perform(project, fetch=false, verbose=false, remote=false)
        @project = project
        @project.repository.fetch if fetch && @project.exists?

        Inkjet.indent do
          print "#{@project.title.cyan} (#{@project.type.capitalize})"
          undent do
            #puts "#{@project.repository.remote}"
            print " #{@project.exists? ? "Initialized".green : "Not Initialized".yellow}"
            print ", #{@project.configured? ? "Configured".green : "Not Configured".yellow}" if @project.exists? && @project.is_a?(::Greenhouse::Projects::Application)
          end

          if @project.exists?
            undent do
              print ", "+"Uncommitted Changes".red if @project.repository.changes?
              print ", "+"Unpushed Branches".blue if @project.repository.ahead?
              print ", "+"Unpulled Branches".yellow if @project.repository.behind?
              print ", "+"Diverged Branches".magenta if @project.repository.diverged?
              print ", "+"Up-to-date".green if !@project.repository.changes? && !@project.repository.ahead? && @project.repository.up_to_date?
            end
            
            puts
            
            if verbose
              Inkjet.indent do
                print_local_changes if @project.repository.changes?
                print_unpushed_branches if @project.repository.ahead?
                print_out_of_sync_branches if @project.repository.out_of_sync?
              end
            end

            Inkjet.indent { print_not_checked_out_branches } if remote && @project.repository.not_checked_out?
          end
        end

      end
    end
  end
end
