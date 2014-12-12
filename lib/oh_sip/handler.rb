require 'pathname'

module OhSip
  class Handler
    def initialize options
      @options = options
      logger_options = {
        :output => STDOUT,
        :info => false,
        :warn => true,
      }
      if @options[:report_passes]
        logger_options[:info] = true
      end
      @logger = OhSip::Logger.new logger_options
    end

    def get_path_for path
      if Pathname.new(path).absolute?
        path
      else
        File.join(@options[:pwd], path)
      end
    end

    def run
      if @options[:list_tests]
        puts "Batch validation tests:"
        print_tests_for(BatchValidator.new)
        puts
        puts "SIP validation tests:"
        print_tests_for(SipValidator.new)
        puts
        puts "OHMS metadata validation tests:"
        print_tests_for(OhmsValidator.new)
      elsif @options[:sip]
        sip_path = get_path_for @options[:sip]
        validator = SipValidator.new @options.merge({:path => sip_path, :logger => @logger})
        validator.run
      else
        h = {
          :logger => @logger
        }
        if @options[:batch]
          h[:path] = get_path_for @options[:batch]
        else
          h[:path] = @options[:pwd]
        end
        if @options[:sips_dir]
          h[:sips_dir] = @options[:sips_dir]
        end
        validator = BatchValidator.new @options.merge(h)
        validator.run
        if @options[:list_restricted]
          puts
          if File.directory?(File.join(h[:path], 'data', 'sips'))
            puts "Restricted interviews:"
            restricted = []
            Dir.glob("#{h[:path]}/data/sips/*").sort.each do |sip|
              path = File.join(sip, 'restricted.txt')
              if File.exist?(path)
                restricted << File.basename(sip)
              end
            end
            if restricted.count > 0
              restricted.each {|interview| puts "* #{interview}"}
            else
              puts "  (No restricted interviews found)"
            end
          else
            # can't happen (we die before getting here if the
            # directory doesn't exist)
            puts "Batch is malformed, so not checking for restricted interviews."
          end
        end
      end
    end

    def print_tests_for(validator)
      validator.tests.each do |test|
        puts "* #{test.to_s.gsub(/_/, ' ').gsub(/\bsip\b/, 'SIP').gsub(/\bohms\b/, 'OHMS')}"
      end
    end
  end
end
