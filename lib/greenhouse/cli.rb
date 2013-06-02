module Greenhouse
  class CLI
    include Scripts::Script

    valid_argument Scripts::Argument.new("-v, --verbose", :valid => [], :summary => "Output additional information from command executions to STDOUT")

    def self.verbose?
      user_arguments.map(&:key).include?("-v")
    end

    def self.exec(cmd)
      if verbose?
        system cmd
      else
        `#{cmd}`
      end
    end
    
    def self.add_arguments(*args)
      keep = []
      args.each_with_index do |arg,a|
        if Commands::exists?(arg)
          begin
            @command = Commands::command(arg)
            @command.set_arguments(*args.slice(a+1,args.length-a))
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

    def self.version=(ver)
      @version = ver
    end

    def self.version
      @version ||= VERSION
    end

    def self.usage
      puts <<USAGE
#{binary} v#{version} 

usage: #{binary} #{valid_arguments.to_s} <command> [<args>]

Arguments:
#{valid_arguments.to_help}

The available greenhouse commands are:
USAGE

      Commands::commands.each do |cmd|
        print "   %-#{Commands::commands.sort { |a,b| a.command_name.length <=> b.command_name.length }.last.command_name.length + 2}s" % cmd.command_name
        puts "# #{cmd.command_summary}"
      end

      puts
      puts "See `#{binary} help <command>` for more information on a specific command."
    end
    
    def self.start
      begin
        set_arguments(*ARGV)
      rescue Scripts::InvalidArgument => e
        puts e.message
        return
      rescue Exception => e
        usage
        return
      end

      if @command.nil?
        usage
        return
      end

      @command.run
    end
  
  end
end
