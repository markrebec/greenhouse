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

        def bundle
          puts "Running Bundler for \e[36m#{@project.title}\e[0m..."
          @project.bundle
          true
        rescue Exception => e
          puts "\e[31mError running Bundler for #{@project.title}\e[0m"
          puts "#{e.class.name}: #{e.message}"
          puts e.backtrace
          # TODO? prompt to continue?
          false
        end

        def clone
          puts "Cloning \e[36m#{@project.title}\e[0m (#{@project.repository.remote}) into #{@project.path}..."
          @project.repository.clone
            
          # Ignore the project's ignored files
          Bundler.with_clean_env do
            @project.chdir do
              @project.ignored.each { |file| `git update-index --assume-unchanged #{file.to_s} 2>&1` if File.exists?(file.to_s) }
            end
          end
          true
        rescue Exception => e
          puts "\e[31mCould not clone #{@project.title}\e[0m"
          puts "#{e.class.name}: #{e.message}"
          puts e.backtrace
          # TODO? prompt to continue?
          false
        end

        def pull
          print "Checking \e[36m#{@project.title}\e[0m git remotes for upstream commits... "
          
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
              puts "\e[33mYou have uncommitted local changes in #{@project.path} on branch #{@project.repository.git.branch.name}\e[0m"
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
                raise "Cound not push local branches" unless push_branches
              rescue
                puts "\e[33mThere was a problem pushing local branches for #{@project.title}\e[0m"
                puts "You may manually resolve conflicts in #{@project.path} and try again."
                puts "\e[33mSkipping #{@project.title}...\e[0m"
                return
              end
            end
            
            return true
          else
            puts "Nothing to push for \e[36m#{@project.title}\e[0m."
          end
        end

        # TODO move this to a logger class
        def indent_spaces(indent=0)
          indent.times.map {" "}.join
        end

        def print_local_changes(indent=0)
          puts "#{indent_spaces indent}\e[33mYou have uncommitted changes in #{@project.title}!\e[0m"
          puts "#{indent_spaces indent}The following files have uncommitted local modifications:"
          puts
          @project.repository.changes.each do |name,file|
            print "#{indent_spaces indent}#{file.untracked ? "U" : file.type}"
            puts "   #{@project.path}/#{name}"
          end
          puts
        end

        def print_unpushed_branches(indent=0)
          puts "#{indent_spaces indent}\e[33mYou have branches in #{@project.title} that haven't been pushed!\e[0m"
          puts
          @project.repository.ahead.each do |branch|
            puts "#{indent_spaces indent}    branch #{branch[0].name} is ahead of #{branch[1].name}/#{branch[0].name}"
          end
          @project.repository.diverged.each do |branch|
            puts "#{indent_spaces indent}    branch #{branch[0].name} and #{branch[1].name}/#{branch[0].name} have diverged"
          end
          puts
        end

        def print_out_of_sync_branches(indent=0)
          puts "#{indent_spaces indent}\e[33mYou have out of sync branches in #{@project.title}\e[0m"
          puts
          @project.repository.behind.each do |branch|
            puts "#{indent_spaces indent}    \e[37mbranch\e[0m #{branch[0].name} \e[37mis behind\e[0m #{branch[1].name}/#{branch[0].name}"
          end

          @project.repository.diverged.each do |branch|
            puts "#{indent_spaces indent}    \e[37mbranch\e[0m #{branch[0].name} \e[37mand\e[0m #{branch[1].name}/#{branch[0].name} \e[37mhave diverged\e[0m"
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
              print "Attempting to merge #{branch[1].name}/#{branch[0].name} into #{branch[0].name} before pushing..."
              @project.repository.git.checkout(branch[0].name)
              @project.repository.git.merge("#{branch[1].name}/#{branch[0].name}")
              puts "\e[32mSuccess.\e[0m"
            rescue
              # TODO detect unmerged files, allow to resolve inline?
              puts "\e[31mFailed! Unresolved conflicts.\e[0m"
              return false
            end
          end

          print "Pushing local branches..."
          @project.repository.push
          puts "\e[32mSuccess.\e[0m"
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
                puts "\e[33mSkipping #{@project.title}...\e[0m"
                return
              elsif %w(c commit).include?(commit)
                begin
                  raise "Could not commit local changes" unless commit_changes
                rescue
                  puts "\e[33mThere was a problem committing local changes to #{@project.title}\e[0m"
                  puts "\e[33mSkipping #{@project.title}...\e[0m"
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
                puts "\e[33mSkipping #{@project.title}...\e[0m"
                return
              elsif %w(p push).include?(push)
                begin
                  raise "Cound not push local branches" unless push_branches
                rescue
                  puts "\e[33mThere was a problem pushing local branches for #{@project.title}\e[0m"
                  puts "You may manually resolve conflicts in #{@project.path} and try again."
                  puts "\e[33mSkipping #{@project.title}...\e[0m"
                  return
                end
              end
            end
          
          end
          
          puts "\e[33mRemoving #{@project.title} project directory...\e[0m"

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
