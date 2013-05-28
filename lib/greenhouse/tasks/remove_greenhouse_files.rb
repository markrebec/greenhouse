module Greenhouse
  module Tasks
    class RemoveGreenhouseFiles
      include Task
        
      # TODO maybe DRY this up, and/or break into individual tasks
      def perform(force=false)
        if Projects::dotenv.exists?
          if !force
            print "Would you like to remove your default configuration file? ([K]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "\e[33mRemoving default config file...\e[0m"
            Projects::dotenv.unlink
          end
        end

        if Projects::projects_file.exists?
          if !force
            print "Would you like to remove your .projects file? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "\e[33mRemoving .projects file...\e[0m"
            Projects::projects_file.unlink
          end
        end
        
        if Projects::ignore_file.exists?
          if !force
            print "Would you like to remove your .ignore file? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "\e[33mRemoving .ignore file...\e[0m"
            Projects::ignore_file.unlink
          end
        end

        if Projects::procfile.exists?
          if !force
            print "Would you like to remove your Procfile? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "\e[33mRemoving Procfile...\e[0m"
            Projects::procfile.unlink
          end
        end
      end
    end
  end
end
