module Greenhouse
  module Tasks
    module ProjectTask
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
      end

      module InstanceMethods
        def self.included(base)
          base.send :alias_method, :klone, :clone
        end

        def bundle(cmd='install')
          puts "Running Bundler for #{@project.title.cyan}..."
          @project.bundle(cmd)
          true
        rescue Exception => e
          puts "Error running Bundler for #{@project.title.cyan}".red
          # TODO? prompt to continue?
          false
        end

        def clone
          puts "Cloning #{@project.title.cyan} (#{@project.repository.remote}) into #{@project.path}..."
          @project.repository.clone
            
          # Ignore the project's ignored files
          Bundler.with_clean_env do
            @project.chdir do
              @project.ignored.each { |file| `git update-index --assume-unchanged #{file.to_s} 2>&1` if File.exists?(file.to_s) }
            end
          end
          true
        rescue Exception => e
          puts "Could not clone #{@project.title.cyan}".red
          puts "#{e.class.name}: #{e.message}"
          puts e.backtrace
          # TODO? prompt to continue?
          false
        end

        def pull
          print "Checking #{@project.title.cyan} git remotes for upstream commits... "
          
          @project.repository.fetch # fetch the latest from remotes
          if @project.repository.out_of_sync?
            puts
            print_out_of_sync_branches
            
            # Un-ignore the project's ignored files before attempting any pulls/merges
            Bundler.with_clean_env do
              @project.chdir do
                @project.ignored.each { |file| `git update-index --no-assume-unchanged #{file.to_s} 2>&1` if File.exists?(file.to_s) }
              end
            end

            merge = nil
            stashed = false
            if @project.repository.changes?(false)
              puts "You have uncommitted local changes in #{@project.path.cyan} on branch #{@project.repository.git.branch.name.white}".yellow
              while !['y','yes','n','no'].include?(merge) do
                print "Would you like to stash your changes and merge the latest commits from upstream? ([y]es/[n]o): "
                merge = STDIN.gets.chomp.downcase
              end

              if ['y','yes'].include?(merge)
                puts "Stashing local changes..."
                stashed = @project.repository.git.branch.name
                @project.repository.stash
              end
            else
              while !['y','yes','n','no'].include?(merge) do
                print "Would you like to attempt to merge the latest commits from upstream? ([y]es/[n]o): "
                merge = STDIN.gets.chomp.downcase
              end
            end

            if ['y','yes'].include?(merge)
              @project.repository.out_of_sync.each do |branch|
                print "Attempting to merge #{branch[1].name}/#{branch[0].name} into #{branch[0].name}..."
                @project.repository.git.checkout(branch[0].name)
                @project.repository.git.merge("#{branch[1].name}/#{branch[0].name}")
                puts "Success."
              end

              if stashed != false
                puts "Popping local stash..."
                @project.repository.git.checkout(stashed)
                @project.repository.pop_stash
              end
              
            end
            
            # Ignore the project's ignored files
            Bundler.with_clean_env do
              @project.chdir do
                @project.ignored.each { |file| `git update-index --assume-unchanged #{file.to_s} 2>&1` if File.exists?(file.to_s) }
              end
            end
            
            return true if ['y','yes'].include?(merge)
          else
            puts "Already up-to-date."
          end
        end

        def push
          if @project.repository.ahead? || @project.repository.diverged?
            print_unpushed_branches

            print "Would you like to push these branches now? ([P]ush/[s]kip): "
            push = STDIN.gets.chomp.downcase

            if %w(s skip).include?(push)
              puts "Skipped #{@project.title}"
              return
            else
              begin
                #raise "Cound not push local branches" unless push_branches
                push_branches
              rescue Exception => e
                puts e.message
                puts e.backtrace
                puts "There was a problem pushing local branches for #{@project.title.cyan}".yellow
                puts "You may manually resolve conflicts in #{@project.path} and try again."
                puts "Skipping #{@project.title.cyan}...".yellow
                return
              end
            end
            
            return true
          else
            puts "Nothing to push for #{@project.title.cyan}"
          end
        end

        def print_local_changes
          puts
          puts "You have uncommitted changes in #{@project.title.cyan}!".red
          puts
          Inkjet.indent do
            @project.repository.changes.each do |name,file|
              puts "#{file.untracked ? "U" : file.type}    #{@project.path}/#{name}"
            end
          end
          puts
        end

        def print_unpushed_branches
          puts
          puts "You have branches in #{@project.title.cyan} that haven't been pushed!".blue
          puts
          Inkjet.indent do
            @project.repository.ahead.each do |branch|
              begin
                rbranch = @project.repository.git.object("#{branch[1].name}/#{branch[0].name}")
                puts "branch #{branch[0].name.bold} is #{"ahead".cyan} of #{branch[1].name.bold}/#{rbranch.name.bold}"
              rescue Exception => e
                puts "branch #{branch[0].name.bold} #{"does not exist".blue} on remote #{branch[1].name.bold}"
              end
            end
            @project.repository.diverged.each do |branch|
              puts "branch #{branch[0].name.bold} and #{branch[1].name.bold}/#{branch[0].name.bold} have #{"diverged".magenta}"
            end
          end
          puts
        end

        def print_out_of_sync_branches
          puts
          puts "You have out of sync branches in #{@project.title.cyan}".yellow
          puts
          Inkjet.indent do
            @project.repository.behind.each do |branch|
              puts "branch #{branch[0].name.bold} is #{"behind".yellow} #{branch[1].name.bold}/#{branch[0].name.bold}"
            end

            @project.repository.diverged.each do |branch|
              puts "branch #{branch[0].name.bold} and #{branch[1].name}/#{branch[0].name.bold} have #{"diverged".magenta}"
            end
          end
          puts
        end

        def print_not_checked_out_branches
          puts
          puts "The following branches are available in #{@project.title.cyan}:".green
          puts
          @project.repository.not_checked_out.each do |branch|
            puts "branch #{branch.full.split("/").last.bold} is #{"available".green} from #{branch.full.split("/")[1].bold}".indent
          end
          puts
        end

        def commit_changes
          add_untracked = nil
          if @project.repository.untracked?
            while !%w(a add p prompt s skip).include?(add_untracked) do
              puts
              puts "You have untracked files in your project:"
              puts
              @project.repository.untracked.each do |name,file|
                puts "U   #{@project.path}/#{name}"
              end
              puts
              print "Would you like to add them all, be prompted for each or skip them? ([a]dd/[p]rompt/[s]kip): "
              add_untracked = STDIN.gets.chomp.downcase
            end

            if %w(a add).include?(add_untracked)
              @project.repository.untracked.each do |name,file|
                @project.repository.add(name)
              end
            elsif %w(p prompt).include?(add_untracked)
              @project.repository.untracked.each do |name,file|
                puts
                addfile = nil
                while !%w(a add s skip).include?(addfile) do
                  print "Do you want to add #{name} to your commit? ([a]dd/[s]kip): "
                  addfile = STDIN.gets.chomp.downcase
                end
                if %w(a add).include?(addfile)
                  @project.repository.add(name)
                  puts "Added #{name}."
                end
              end
            end
          end

          add_modified = nil
          if @project.repository.unstaged?
            while !%w(a add p prompt s skip).include?(add_modified) do
              puts
              puts "You have modified files in your project:"
              puts
              @project.repository.unstaged.each do |name,file|
                puts "#{file.type}   #{@project.path}/#{name}"
                puts file.sha_index
              end
              puts
              print "Would you like to add them all, be prompted for each or skip them? ([a]dd/[p]rompt/[s]kip): "
              add_modified = STDIN.gets.chomp.downcase
            end

            if %w(a add).include?(add_modified)
              @project.repository.unstaged.each do |name,file|
                @project.repository.add(name)
              end
            elsif %w(p prompt).include?(add_modified)
              @project.repository.unstaged.each do |name,file|
                puts
                addfile = nil
                while !%w(a add s skip).include?(addfile) do
                  print "Do you want to add #{name} to your commit? ([a]dd/[s]kip): "
                  addfile = STDIN.gets.chomp.downcase
                end
                if %w(a add).include?(addfile)
                  @project.repository.add(name)
                  puts "Added #{name}."
                end
              end
            end
          end
            
          if ![nil,'s','skip'].include?(add_untracked) || ![nil,'s','skip'].include?(add_modified)
            puts
            puts "Changes to be committed:"
            puts
            @project.repository.staged.each do |name,file|
              print file.untracked ? "U" : file.type
              puts "   #{@project.path}/#{name}"
              puts file.sha_index
            end
            puts
          end

          puts "Enter a commit message (leave blank to skip): "
          message = STDIN.gets.chomp
          return if message.empty?
          
          @project.repository.commit(message)
          return true
        end

        def push_branches
          @project.repository.out_of_sync.each do |branch|
            begin
              # skip the merge if there's no remote branch
              # TODO maybe check remote branches instead, or even better check for remote branch changes
              rbranch = @project.repository.git.object("#{branch[1].name}/#{branch[0].name}")
              begin
                print "Attempting to merge #{branch[1].name}/#{branch[0].name} into #{branch[0].name} before pushing..."
                @project.repository.git.checkout(branch[0].name)
                @project.repository.git.merge("#{branch[1].name}/#{branch[0].name}")
                puts "Success.".green
              rescue
                # TODO detect unmerged files, allow to resolve inline?
                puts "Failed! Unresolved conflicts.".red
                return false
              end
            rescue
            end
          end

          print "Pushing local branches..."
          @project.repository.branches.local.each do |branch|
            @project.repository.push('origin', branch.name)
          end
          puts "Success.".green
          return true
        end

        def purge(force=false)
          return unless @project.exists?

          @project.repository.fetch # fetch the latest from remotes
          if @project.repository.changes? || @project.repository.ahead? || @project.repository.diverged?
            
            # Prompt to take action if there are local changes
            if @project.repository.changes?
              print_local_changes
              
              puts "You can skip this project, commit your changes now or remove the project (and lose your changes)."
              commit = nil
              while !%w(c commit s skip r remove).include?(commit) do
                print "What would you like to do? ([c]ommit/[s]kip/[r]emove): "
                commit = STDIN.gets.chomp.downcase
              end

              if %w(s skip).include?(commit)
                puts "Skipping #{@project.title.cyan}...".yellow
                return
              elsif %w(c commit).include?(commit)
                begin
                  raise "Could not commit local changes" unless commit_changes
                rescue
                  puts "There was a problem committing local changes to #{@project.title.cyan}".red
                  puts "Skipping #{@project.title.cyan}...".yellow
                  return
                end
              end
            end

            # Prompt to take action if there are unpushed branches
            if @project.repository.ahead? || @project.repository.diverged?
              print_unpushed_branches

              puts "You can skip this project, push your branches now or remove the project (and lose your changes)."
              push = nil
              while !%w(p push s skip r remove).include?(push) do
                print "What would you like to do? ([p]ush/[s]kip/[r]emove): "
                push = STDIN.gets.chomp.downcase
              end

              if %w(s skip).include?(push)
                puts "Skipping #{@project.title.cyan}...".yellow
                return
              elsif %w(p push).include?(push)
                begin
                  raise "Cound not push local branches" unless push_branches
                rescue
                  puts "There was a problem pushing local branches for #{@project.title.cyan}".yellow
                  puts "You may manually resolve conflicts in #{@project.path} and try again."
                  puts "Skipping #{@project.title.cyan}...".yellow
                  return
                end
              end
            end
          
          end
          
          puts "Removing #{@project.title.cyan} project directory...".yellow

          Projects::procfile.processes.delete_if do |key,process|
            # this is sort of generic, just checks for the project name in the key/cmd
            key.match(/\A.*#{@project.name}.*\Z/) || process.command.match(/\A.*#{@project.name}.*\Z/)
          end
          Projects::procfile.write

          @project.destroy
        end
      end
    end
  end
end
