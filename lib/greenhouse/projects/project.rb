module Greenhouse
  module Projects
    class Project
      attr_accessor :name, :repository, :title

      class << self
        attr_reader :subclasses

        # Keep track of inheriting classes (to use as project "types")
        def inherited(subclass)
          (@subclasses ||= [self]) << subclass
        end
      end

      
      def initialize(name, args={})
        @name = name
        @title = args.delete(:title) || name.camelize
        @ignored = (args.has_key?(:ignore) ? [args.delete(:ignore)] : []).flatten
        @repository = Repository.new(name, args)
        @ignore_file = Resources::IgnoreFile.new("#{path}/.ignore")
      end

      def ignored
        Projects.ignored.concat(@ignore_file.ignored).concat(@ignored)
      end
    
      def chdir(&block)
        Dir.chdir(path, &block)
      end

      # Return the local path to the project repo
      def path
        @repository.path
      end

      def gemfile
        return nil unless gemfile?
        "#{path}/Gemfile"
      end

      def gemfile?
        chdir { return File.exists?("Gemfile") }
      end

      # Check if the repository exists
      def exists?
        @repository.exists?
      end

      def type
        self.class.name.underscore.split('/').last
      end

      def to_arg
        Scripts::Argument.new(name, :summary => "#{title} (#{type.capitalize})")
      end

      # Go into the local directory and run Bundler
      def bundle(cmd='install')
        raise "Directory does not exist: #{path}" unless exists?
        Dir.chdir(path) do
          Bundler.with_clean_env do
            # TODO look into using Bundler to install instead of executing system cmd
            Greenhouse::CLI::exec "bundle #{cmd.to_s} 2>&1"
          end
        end
      end

      # Remove the project directory
      def destroy
        @repository.destroy # use the repository object to destroy itself/directory
      end

    end
  end
end
