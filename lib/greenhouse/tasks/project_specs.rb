module Greenhouse
  module Tasks
    class ProjectSpecs
      include Task
      include ProjectTask
      
      def rspec_output_file
        "#{@project.path}/tmp/rspec.json"
      end

      def coverage_output_file
        "#{@project.path}/tmp/coverage_data"
      end

      def perform(project)
        @project = project
        
        Bundler.with_clean_env do
          @project.chdir do
            puts "Running specs for \e[36m#{@project.title}\e[0m..."
            File.unlink(rspec_output_file) if File.exists?(rspec_output_file)
            File.unlink(coverage_output_file) if File.exists?(coverage_output_file)
            Greenhouse::CLI.exec "bundle exec rspec --format=json --out=#{rspec_output_file}"
          end
        end

        @results = Resources::Specs::Result.new(@project, rspec_output_file, coverage_output_file)
      end
    end
  end
end
