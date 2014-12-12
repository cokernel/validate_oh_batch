require 'find'
require 'oh_sip/validator'

module OhSip
  class BatchValidator
    include Validator

    def initialize options = nil
      set_default_options(options)
      if options
        @sips_dir = File.join(@path, 'data', 'sips')
        if @options[:sips_dir]
          @alt_sips_dir = File.join(@path, @options[:sips_dir])
        end
        @real_sips_dir = @alt_sips_dir ? @alt_sips_dir : @sips_dir
      end
      @tests = [
        :batch_exists,
        :batch_has_bagit_layout,
        :batch_has_sips_directory,
      ]
      if options and options[:check_fixity]
        @tests << :batch_is_a_valid_bag
      end
    end

    def batch_is_a_valid_bag
      bag = BagIt::Bag.new @path
      if bag.valid?
        @logger.ok
      else
        @logger.fatal("Batch #{@path} is not a valid BagIt bag")
      end
    end

    def batch_has_bagit_layout
      unless File.exist?(File.join(@path, 'bagit.txt'))
        @logger.fatal("Batch #{@path} is not a valid bag - bagit.txt is missing")
        return
      end

      unless File.directory?(File.join(@path, 'data'))
        @logger.fatal("Batch #{@path} is not a valid bag - data directory is missing")
        return
      end

      stray_files = []
      Dir.glob("#{@path}/*").each do |path|
        file = File.basename path
        unless file =~ /^bagit.txt$/ or file =~ /^bag-info.txt$/ or file =~ /^(tag)?manifest-(\w+).txt$/ or file =~ /^data/
          stray_files << file
        end
      end

      if stray_files.count > 0
        @logger.fatal("Batch #{@path} is not a valid bag - bag directory includes files that should be in a data directory: #{stray_files.join(', ')}")
        return
      end

      manifest_files = []
      Dir.glob("#{@path}/*").each do |path|
        file = File.basename path
        if file =~ /^manifest-(\w+).txt$/
          manifest_files << file
        end
      end

      unless manifest_files.count > 0
        @logger.fatal("Batch #{@path} is not a valid bag - no manifest-***.xml file found")
        return
      end

      @logger.ok
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
