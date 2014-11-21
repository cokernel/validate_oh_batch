module OhSip
  module Validator
    attr_reader :tests

    def self.included(base)
      base.class_exec do
        def set_default_options options = nil
          if options
            @options = options
            @path = @options[:path]
            @logger = @options[:logger]
            @live = true
            @tests ||= []
          end
        end
      end
    end

    def run
      @tests.each do |test|
        send(test) if @live
      end

      descend

      unless @options[:partial]
        @logger.summarize
      end

      @live
    end

    def descend
    end
  end
end
