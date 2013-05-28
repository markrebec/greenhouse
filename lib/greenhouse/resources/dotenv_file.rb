module Greenhouse
  module Resources
    class DotenvFile
      include FileResource

      attr_reader :config

      class ConfigVars < Hash
        def format_key(key)
          key.to_s.gsub(/[^a-z\d_]+/i, "_").upcase
        end

        def [](key)
          super(format_key(key))
        end

        def []=(key, value)
          super(format_key(key), value)
        end

        def initialize(hash={})
          hash.each { |k,v| self[k] = v }
        end
      end

      def config=(hash)
        @config = ConfigVars.new(hash)
      end

      def reload
        @config = ConfigVars.new
        return @config unless exists?
        # pulled this straight from Dotenv, too bad there's no simple Dotenv.parse method in the gem
        read do |line|
          if line =~ /\A(?:export\s+)?([\w\.]+)(?:=|: ?)(.*)\z/
            key = $1
            case val = $2
            # Remove single quotes
            when /\A'(.*)'\z/ then @config[key] = $1
            # Remove double quotes and unescape string preserving newline characters
            when /\A"(.*)"\z/ then @config[key] = $1.gsub('\n', "\n").gsub(/\\(.)/, '\1')
            else @config[key] = val
            end
          end
        end
        @config
      end

      def write
        open("w") do |f|
          @config.each do |key,val|
            f.write("#{key}=#{val}\n")
          end
        end
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
