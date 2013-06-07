module Greenhouse
  module Tasks
    class ProjectStatus
      include Task
      include ProjectTask

      def perform(project, verbose=false)
        @project = project
        @project.repository.not_checked_out
        
        @project.repository.fetch if verbose && @project.exists?

        puts "  \e[36m#{@project.title}\e[0m (#{@project.type.capitalize})"
        puts "    #{@project.repository.remote}"
        puts "    #{@project.exists? ? "\e[32mInitialized" : "\e[33mNot Initialized"}\e[0m"
        puts "    #{@project.configured? ? "\e[32mConfigured" : "\e[33mNot Configured"}\e[0m" if @project.exists? && @project.is_a?(::Greenhouse::Projects::Application)

        if @project.exists?
          if !verbose
            puts "    \e[33mUncommitted Changes\e[0m" if @project.repository.changes?
            puts "    \e[33mUnpushed Branches\e[0m" if @project.repository.ahead?
            puts "    \e[33mUnpulled Branches\e[0m" if @project.repository.behind?
            puts "    \e[33mDiverged Branches\e[0m" if @project.repository.diverged?
          end

          if !@project.repository.changes? && !@project.repository.ahead? && @project.repository.up_to_date?
            puts "    \e[32mUp-to-date\e[0m"
          elsif verbose
            print_local_changes(4) if @project.repository.changes?
            print_unpushed_branches(4) if @project.repository.ahead?
            print_out_of_sync_branches(4) if @project.repository.out_of_sync?
            print_not_checked_out_branches(4) if @project.repository.not_checked_out?
          end
        end

      end
    end
  end
end
