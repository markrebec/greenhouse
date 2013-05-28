module Greenhouse
  module Resources
    class IgnoreFile
      include FileResource
      
      class IgnoredFiles < Array
        
        def unshift(file)
          if !file.is_a?(IgnoredFile)
            file = IgnoredFile.new(file, @ignore_file.lines.length)
          end
          super(file)
          @ignore_file.lines[file.line] = file.to_s
        end

        def push(file)
          if !file.is_a?(IgnoredFile)
            file = IgnoredFile.new(file, @ignore_file.lines.length)
          end
          super(file)
          @ignore_file.lines[file.line] = file.to_s
        end

        def <<(file)
          push(file)
        end

        def []=(index,file)
          delete_at index if index < length
          file = IgnoredFile.new(file, @ignore_file.lines.length) if !file.is_a?(IgnoredFile)
          super(index,file)
          @ignore_file.lines[file.line] = file.to_s
        end

        def delete(filename)
          # TODO delete any comments immediately preceding the filename
          deleted = super(select { |f| f.file == filename}.first)
          @ignore_file.ignored.each do |ignored|
            next if ignored.line < deleted.line
            ignored.line -= 1
          end
          line = @ignore_file.lines.slice!(deleted.line,1)
          deleted
        end

        def delete_at(index)
          delete self[index].file
        end

        def delete_if(&block)
          select(&block).map { |ignored| delete ignored.file }
        end

        def keep_if(&block)
          kept = select(&block)
          clone.select { |ignored| !kept.map(&:file).include?(ignored.file) }.map { |ignored| delete ignored.file }
        end

        def initialize(ignore_file)
          @ignore_file = ignore_file
          super()
        end
      end

      class IgnoredFile
        attr_accessor :file, :line

        def to_s
          @file.to_s
        end

        def inspect
          to_s
        end

        def initialize(file, line)
          @file = file
          @line = line
        end
      end

      attr_accessor :ignored

      def write
        ignored.each { |ignored| lines[ignored.line] = ignored.to_s}
        open('w') do |ifile|
          lines.each do |line|
            ifile.write "#{line}\n"
          end
        end
      end
      alias_method :save, :write

      def reload
        @ignored = IgnoredFiles.new(self)
        return @ignored unless exists?
        read do |line,l|
          next if line.strip[0] == "#" || line.strip.empty?
          @ignored << IgnoredFile.new(line,l)
        end
        @ignored
      end

      def unlink
        super
        reload
      end

      def initialize(path)
        super
        reload
      end
    end
  end
end
