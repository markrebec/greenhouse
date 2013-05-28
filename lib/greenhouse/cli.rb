module Greenhouse
  class CLI
    include Scripts::Script

    valid_arguments("-v")

    def self.verbose
      @verbose || false
    end
    
    def self.verbose?
      verbose == true
    end

    def self.verbose=(v)
      @verbose = v
      @verbose
    end

    def self.exec(cmd)
      if verbose?
        system cmd
      else
        `#{cmd}`
      end
    end
    
    def self.arguments(*args)
      keep = []
      args.each_with_index do |arg,a|
        if Commands::exists?(arg)
          begin
            @command = Commands::command(arg)
            @command.arguments(*args.slice(a+1,args.length-a))
          rescue Scripts::InvalidArgument => e
            puts e.message
            Commands::command(arg).usage
            exit 1
          end
          break
        end
        keep << arg
      end
      super(*keep)
    end

    def self.binary=(bin)
      @binary = bin
    end

    def self.binary
      @binary ||= "greenhouse"
    end

    def self.command_name
      binary
    end

    def self.usage
      puts <<USAGE
usage: #{command_name} #{valid_arguments.to_s} <command> [<args>]
        
The available greenhouse commands are:
USAGE

      Commands::commands.each do |cmd|
        print "   %-#{Commands::commands.sort { |a,b| a.command_name.length <=> b.command_name.length }.last.command_name.length + 2}s" % cmd.command_name
        puts cmd.command_summary
      end

      puts
      puts "See `#{command_name} help <command>` for more information on a specific command."
    end
    
    def self.start
      arguments(*ARGV)
      verbose = arguments.map(&:key).include?("-v")
      
      if @command.nil?
        usage
        exit 1
      end

      @command.run
    end
  
  end
end