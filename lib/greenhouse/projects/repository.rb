module Greenhouse
  module Projects
    class Repository
      attr_accessor :local, :remote
      alias_method :path, :local

      def method_missing(meth, *args)
        return git.send(meth, *args) if git.respond_to?(meth)
        super
      end

      # Clone the remote into the local path
      def clone
        raise "Repository already exists: #{@local}" if cloned?
        Git.clone(@remote, @local.split("/").last)
      end

      # Check if the remote has been cloned locally
      def cloned?
        File.exists?(@local) && @git ||= Git.open(@local)
      end
      alias_method :exists?, :cloned?

      # Check whether there are any uncommited local changes
      def changes?(untracked=true)
        raise "Repository does not exist: #{@local}" unless cloned?
        !changes(untracked).empty?
      end

      # Get a list of all local changes (modified, added, deleted & untracked)
      def changes(include_untracked=true)
        raise "Repository does not exist: #{@local}" unless cloned?
        changes = changed.merge(git.status.added).merge(git.status.deleted)
        changes.merge!(untracked) if include_untracked
        changes
      end

      def changed?
        !changed.empty?
      end

      def changed
        git.status.changed.select { |name,file| !git.diff('HEAD', '--').path(name).to_s.empty? }
      end

      def untracked
        git.status.untracked.select { |name,file| !name.match(/\Atmp\/.*\Z/) } # temporary hack to avoid untracked tmp files, since they're not being properly ignored(?)
      end

      def untracked?
        !untracked.empty?
      end

      def staged
        changed.merge(git.status.added).merge(git.status.deleted).delete_if { |name,file| file.sha_index.empty? || file.sha_index == '0000000000000000000000000000000000000000' }
      end

      def staged?
        !staged.empty?
      end

      def unstaged
        changed.merge(untracked).select { |name,file| file.sha_index.empty? || file.sha_index == '0000000000000000000000000000000000000000' }
      end

      def unstaged?
        !unstaged.empty?
      end

      # Return the results of `ls-files --others` to list ignored/untracked files
      def others
        git.chdir do
          return `git ls-files --others`.split("\n")
        end
      end

      def not_checked_out?
        !not_checked_out.empty?
      end

      # Remote branches that aren't checked out locally
      def not_checked_out
        git.branches.remote.select do |branch|
          !branch.full.match(/HEAD/) && !git.branches.local.map(&:name).include?(branch.full.split("/").last)
        end
      end

      # Check whether local branches are synced with the remotes
      def synced?
        unsynced.empty?
      end
      
      # Return any unsynced branches for all remotes
      def unsynced
        branches = []
        git.branches.local.each do |branch|
          git.remotes.each do |remote|
            lcommit = git.object(branch.name).log.first
            begin
              rcommit = git.object("#{remote.name}/#{branch.name}").log.first
              next if lcommit.sha == rcommit.sha
              branches << [branch, remote]
            rescue # can this just be an ensure? will the next still work without ensuring?
              branches << [branch, remote]
            end
          end
        end
        branches
      end

      # Check whether there are unpushed local changes on all branches/remotes
      def ahead?
        !ahead.empty?
      end
      
      # Return any unpushed local changes on all branches/remotes
      def ahead
        unsynced.select do |branch|
          lbranch = git.object(branch[0].name)
          begin
            rbranch = git.object("#{branch[1].name}/#{branch[0].name}")
            lcommit = lbranch.log.first
            rcommit = rbranch.log.first
          
            !rbranch.log.map(&:sha).include?(lcommit.sha) && lbranch.log.map(&:sha).include?(rcommit.sha)
          rescue
            true
          end
          
          #lcommit.date <= rcommit.date
        end
      end

      # Check if there are any unpulled changes on all branches/remotes
      def behind?
        !behind.empty?
      end
      
      # Return any unpulled changes on all branches/remotes
      def behind
        unsynced.select do |branch|
          lbranch = git.object(branch[0].name)
          begin
            rbranch = git.object("#{branch[1].name}/#{branch[0].name}")
            lcommit = lbranch.log.first
            rcommit = rbranch.log.first
            
            rbranch.log.map(&:sha).include?(lcommit.sha) && !lbranch.log.map(&:sha).include?(rcommit.sha)
          rescue
            false
          end
          
          #lcommit.date >= rcommit.date
        end
      end

      def diverged?
        !diverged.empty?
      end

      def diverged
        unsynced.select do |branch|
          lbranch = git.object(branch[0].name)
          begin
            rbranch = git.object("#{branch[1].name}/#{branch[0].name}")
            lcommit = lbranch.log.first
            rcommit = rbranch.log.first
          
            !rbranch.log.map(&:sha).include?(lcommit.sha) && !lbranch.log.map(&:sha).include?(rcommit.sha)
          rescue
            false
          end
        end
      end

      def up_to_date?
        !out_of_sync?
      end

      def out_of_sync?
        behind? || diverged?
      end

      def out_of_sync
        unsynced.select do |branch|
          lbranch = git.object(branch[0].name)
          begin
            rbranch = git.object("#{branch[1].name}/#{branch[0].name}")
            lcommit = lbranch.log.first
            rcommit = rbranch.log.first
          
            (rbranch.log.map(&:sha).include?(lcommit.sha) && !lbranch.log.map(&:sha).include?(rcommit.sha)) ||
            (!rbranch.log.map(&:sha).include?(lcommit.sha) && !lbranch.log.map(&:sha).include?(rcommit.sha))
          rescue
            true
          end
        end
      end

      def stash
        git.chdir { `git stash 2>&1` }
      end

      def pop_stash
        git.chdir { `git stash pop 2>&1` }
      end

      # Remove the local repository
      def destroy
        FileUtils.rm_rf @local
      end

      def git
        @git ||= Git.open(@local)
        @git
      end

      protected

      def initialize(name, args={})
        raise "A git remote is required." unless args.has_key?(:remote)
        @local = File.expand_path(args[:local] || name)
        @remote = args[:remote]# || "git@github.com:Graphicly/#{name}.git"
      end

    end
  end
end
