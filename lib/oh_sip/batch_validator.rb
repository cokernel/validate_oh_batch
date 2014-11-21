require 'find'
require 'oh_sip/validator'

module OhSip
  class BatchValidator
    include Validator

    def initialize options = nil
      set_default_options(options)
      if options
        @sips_dir = File.join(@path, 'sips')
        if @options[:sips_dir]
          @alt_sips_dir = File.join(@path, @options[:sips_dir])
        end
        @real_sips_dir = @alt_sips_dir ? @alt_sips_dir : @sips_dir
      end
      @tests = [
        :batch_exists,
        :batch_has_sips_directory,
      ]
    end

    def descend
      if @live
        Find.find(@real_sips_dir) do |path|
          if @live
            if File.directory?(path) and (path != @real_sips_dir)
              sip_validator = SipValidator.new @options.merge({:path => path,
                                                 :logger => @logger,
                                                 :partial => true})
              @live = sip_validator.run
              Find.prune
            end
          end
        end
      end
    end

    def batch_has_sips_directory
      if File.directory?(@sips_dir)
        @logger.ok
      elsif @alt_sips_dir
        if File.directory?(@alt_sips_dir)
          if @options[:ignore_filename_errors]
            @logger.ok
          else
            @logger.warn("Non-standard SIPs directory found in #{@alt_sips_dir}")
          end
        else
          @logger.fatal("Non-standard SIPs directory #{@alt_sips_dir} specified, but it does not exist")
          @live = false
        end
      else
        @logger.fatal("No SIPs directory found in #{@sips_dir}")
        @live = false
      end
    end

    def batch_exists
      if File.directory?(@path)
        @logger.ok("Found batch directory in #{@path}")
      else
        @logger.fatal("No batch found in #{@path}")
        @live = false
      end
    end
  end
end
