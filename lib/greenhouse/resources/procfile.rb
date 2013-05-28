module Greenhouse
  module Resources
    class Procfile
      include FileResource
      
      class Processes < Hash
        def [](key)
          super(key.to_s)
        end

        def []=(key, value)
          if value.is_a?(Process)
            super(key.to_s, value)
          else
            parr = value.strip.split(":")
            key = parr.slice!(0)
            command = parr.join(":").strip
            # TODO might need to rework this line index, won't account for blank/comment lines at the end of the file
            value = Process.new(key, command, (values.map(&:line).sort.last || -1) + 1)
            super(key.to_s, value)
          end
          @procfile.lines[value.line] = value.to_s
        end

        def delete(key)
          del = super(key)
          @procfile.processes.each do |key,process|
            next if process.line < del.line
            process.line -= 1
          end
          line = @procfile.lines.slice!(del.line,1)
          del
        end

        def delete_if(&block)
          select(&block).keys.map { |key| delete key }
        end

        def keep_if(&block)
          kept = select(&block)
          clone.select { |key,process| !kept.keys.include?(key) }.keys.map { |key| delete key }
        end

        def initialize(procfile)
          @procfile = procfile
        end
      end

      class Process
        attr_accessor :key, :command, :line
        
        def enabled?
          !@disabled
        end

        def disabled?
          @disabled
        end

        def enable
          @disabled = false
        end

        def disable
          @disabled = true
        end

        def to_s
          "#{"#" if disabled?}#{key}: #{command}"
        end

        def inspect
          to_s
        end

        def initialize(key, command, line)
          @line = line
          @disabled = key.strip[0] == "#"
          @key = key.gsub(/\A#+/, "")
          @command = command
        end
      end
      
      def disabled(refresh=false)
        return @processes.select { |key,process| process.disabled? } unless refresh || @processes.nil? || @processes.empty?
        reload.select { |key,process| process.disabled? }
      end
      
      def enabled(refresh=false)
        return @processes.select { |key,process| process.enabled? } unless refresh || @processes.nil? || @processes.empty?
        reload.select { |key,process| process.enabled? }
      end
      
      def processes(refresh=false)
        return @processes unless refresh || @processes.nil? || @processes.empty?
        reload
      end

      def process_exists?(key)
        processes.keys.include?(key.to_s)
      end

      def process(key)
        processes.values.select { |p| p.key.to_s == key.to_s }.first
      end

      def write
        processes.values.each { |process| lines[process.line] = process.to_s}
        open('w') do |pfile|
          lines.each do |line|
            pfile.write "#{line}\n"
          end
        end
        reload
      end
      alias_method :save, :write

      def reload
        @processes = Processes.new(self)
        return @processes unless exists?
        
        read do |line,l|
          if line.match(/\A[#]*[a-z0-9_]+:\s*.*\Z/)
            parr = line.strip.split(":")
            key = parr.slice!(0)
            command = parr.join(":").strip
            process = Process.new(key, command, l)
            @processes[process.key] = process
          end
        end
        @processes
      end

      def unlink
        super
        reload
      end

      def initialize(path)
        super
      end
    end
  end
end
