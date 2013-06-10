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
            puts "Removing default config file...".yellow
            Projects::dotenv.unlink
          end
        end

        if Projects::projects_file.exists?
          if !force
            print "Would you like to remove your .projects file? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "Removing .projects file...".yellow
            Projects::projects_file.unlink
          end
        end
        
        if Projects::ignore_file.exists?
          if !force
            print "Would you like to remove your .ignore file? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "Removing .ignore file...".yellow
            Projects::ignore_file.unlink
          end
        end

        if Projects::procfile.exists?
          if !force
            print "Would you like to remove your Procfile? ([k]eep/[r]emove): "
            remove = STDIN.gets.chomp.downcase
          end

          if ['r','remove'].include?(remove) || force
            puts "Removing Procfile...".yellow
            Projects::procfile.unlink
          end
        end
      end
    end
  end
end
