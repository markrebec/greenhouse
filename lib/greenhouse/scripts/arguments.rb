module Greenhouse
  module Scripts
    class Arguments < Array
      
      def to_s
        map do |arg|
          #if arg.valid.nil? || arg.valid.empty?
            "[#{arg.keys.join(", ")}]"
          #else
          #  "[#{arg.keys.join(", ")} = (#{arg.valid.join("|")})]"
          #end
        end.join(" ")
      end

      def to_help
        map do |arg|
          "  #{"%-#{sort { |a,b| a.keys.join(", ").length <=> b.keys.join(", ").length }.last.keys.join(", ").length + 2}s" % arg.keys.join(", ")}# #{arg.summary}"
        end.join("\n")
      end

      protected

      def initialize
        super
      end
    end
  end
end
