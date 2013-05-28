module Greenhouse
  module Scripts
    module Script
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def self.extended(base)
        end
        
        def run
          @script ||= new
          raise "You have not defined a `run` method for your script." unless @script.respond_to?(:run)
          @script.run
        end

        def validate_arguments(val=nil)
          return validate_arguments? if val.nil?
          @validate_arguments = val
        end

        def validate_arguments?
          @validate_arguments = true if @validate_arguments.nil?
          @validate_arguments
        end

        def valid_argument(arg)
          @valid_args ||= Arguments.new
          if arg.is_a?(Argument)
            @valid_args << arg
          elsif arg.is_a?(Hash)
            @valid_args << Argument.new(arg.keys.first.to_s, arg.values.first)
          elsif arg.is_a?(Array)
            @valid_args << Argument.new(arg[0].to_s, (arg.length > 1 ? arg[1] : []))
          else
            @valid_args << Argument.new(arg.to_s)
          end
          @valid_args.last
        end

        def valid_arguments(*args)
          @valid_args ||= Arguments.new
          return @valid_args if args.empty?
          
          args.each { |arg| valid_argument(arg) }
          @valid_args
        end
        
        def project_argument(proj)
          @valid_projs ||= Arguments.new
          if proj.is_a?(Argument)
            @valid_projs << proj
          elsif proj.is_a?(Hash)
            @valid_projs << Argument.new(proj.keys.first.to_s, proj.values.first)
          elsif proj.is_a?(Array)
            @valid_projs << Argument.new(proj[0].to_s, (proj.length > 1 ? proj[1] : []))
          else
            @valid_projs << Argument.new(proj.to_s)
          end
          @valid_projs.last
        end

        def project_arguments(*projs)
          @valid_projs ||= Arguments.new
          return @valid_projs if projs.empty?
          
          projs.each { |proj| project_argument(proj) }
          @valid_projs
        end

        def arguments(*args)
          @arguments ||= nil
          return @arguments unless @arguments.nil?
          @arguments = Arguments.new
          args.each_with_index do |arg,a|
            argarr = arg.split("=")
            argkey = argarr.slice!(0)
            
            if !valid_arguments.concat(project_arguments).map(&:keys).any? { |keys| keys.include?(argkey) } && !arg.match(/\A(-)+[a-z0-9\-]=?.*\Z/i) && (a > 0 && args[a-1].match(/\A(-)+[a-z0-9\-]=?.*\Z/i)) && !@arguments.empty?
              @arguments.last.value = arg
              next
            end

            if validate_arguments?
              raise InvalidArgument, "Invalid Argument: #{arg}" unless valid_arguments.concat(project_arguments).map(&:keys).any? { |keys| keys.include?(argkey) }
              @arguments << valid_arguments.concat(project_arguments).select { |varg| varg.keys.include?(argkey) }.first
            else
              valid_arg = valid_arguments.concat(project_arguments).select { |varg| varg.keys.include?(argkey) }.first
              @arguments << (valid_arg || Argument.new(argkey))
            end
            @arguments.last.value = argarr.join("=") unless argarr.empty?
          end
          @arguments
        end
      end

      module InstanceMethods
        %w(arguments valid_arguments project_arguments).each do |method|
          define_method method do |*args|
            self.class.send method, *args
          end
        end
      end
    
    end
  end
end
