require 'bagit'
require 'digest'
require 'find'
require 'pathname'
require 'oh_sip/validator'

module OhSip
  class SipValidator
    include Validator

    def initialize options = nil
      set_default_options(options)
      if @path
        @base = File.basename(@path)
      end
      @tests = [
        :sip_exists,
        :sip_filenames_are_alphanumeric_plus_underscore,
        :sip_filenames_begin_with_the_interview_name,
        :sip_has_bagit_layout,
        :sip_has_ohms_metadata_file,
        :sip_has_valid_ohms_metadata_file,
      ]
      if @path
        @master = File.join @path, 'data', 'master'
      end
      if @options and @options[:check_fixity]
        @tests << :sip_is_a_valid_bag
      end
    end

    def sip_is_a_valid_bag
      bag = BagIt::Bag.new @path
      if bag.valid?
        @logger.ok
      else
        @logger.fatal("SIP #{@path} is not a valid BagIt bag")
      end
    end

    def sip_has_bagit_layout
      unless File.exist?(File.join(@path, 'bagit.txt'))
        @logger.fatal("SIP #{@path} is not a valid bag - bagit.txt is missing")
        return
      end

      unless File.directory?(File.join(@path, 'data'))
        @logger.fatal("SIP #{@path} is not a valid bag - data directory is missing")
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
        @logger.fatal("SIP #{@path} is not a valid bag - bag directory includes files that should be in a data directory: #{stray_files.join(', ')}")
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
        @logger.fatal("SIP #{@path} is not a valid bag - no manifest-***.xml file found")
        return
      end

      @logger.ok
    end

    def ohms_filename
      File.join(@path, "data", "#{@base}_ohm.xml")
    end

    def sip_has_valid_ohms_metadata_file
      ohms_validator = OhmsValidator.new @options.merge({:file => ohms_filename,
                                                         :logger => @logger,
                                                         :partial => true})
      @live = ohms_validator.run
    end

    def sip_has_ohms_metadata_file
      if File.exist? ohms_filename
        @logger.ok
      else
        @logger.fatal("SIP #{@base}: missing OHMS metadata file, expected in #{ohms_filename}")
        @live = false
      end
    end

    def is_safely_deletable(filename)
      filename[0] == '.' or
      ['.gpk', '.gk', '.mrk'].include?(File.extname(filename)) or
      filename.gsub(/\..*/) =~ /_mez/
    end

    def is_valid_format?(filename)
      if is_safely_deletable(filename)
        true 
      else
        base = filename.gsub(/\./, '')
        base =~ /^[0-9a-z_]+$/
      end
    end

    def is_restriction_marker?(filename)
      'restricted.txt' == filename
    end

    def begins_with_the_interview_name?(filename)
      if is_safely_deletable(filename) or
         is_restriction_marker?(filename)
        true 
      else
        base = filename.gsub(/\./, '')
        base =~ /^#{@base}/
      end
    end

    def sip_filenames_begin_with_the_interview_name
      if @options[:ignore_filename_errors]
        @logger.ok
        return
      end
      valid = true
      if File.directory?(File.join(@path, 'data'))
        Find.find(File.join(@path, 'data')) do |subpath|
          if File.file?(subpath)
            filename = File.basename(subpath)
            unless begins_with_the_interview_name?(filename)
              relative = Pathname.new(subpath).
                        relative_path_from(Pathname.new @path)
              @logger.warn("SIP #{@base}: filename #{relative} has incorrect prefix, should be #{@base}")
              valid = false
            end
          end
        end
      else
        @logger.fatal("SIP #{@base} has no data directory")
        return
      end
      if valid
        @logger.ok
      else
        @logger.warn("SIP #{@base} includes filenames with incorrect prefix")
      end
    end

    def sip_filenames_are_alphanumeric_plus_underscore
      if @options[:ignore_filename_errors]
        @logger.ok
        return
      end
      valid = true
      if File.directory?(File.join(@path, 'data'))
        Find.find(File.join(@path, 'data')) do |subpath|
          filename = File.basename(subpath)
          unless is_valid_format?(filename)
            @logger.warn("SIP #{@base}: filename #{subpath} has invalid characters")
            valid = false
          end
        end
      else
        @logger.fatal("SIP #{@base} has no data directory")
        return
      end
      if valid
        @logger.ok
      else
        @logger.warn("SIP #{@base} includes filenames with invalid characters")
      end
    end

    def sip_exists
      if File.directory?(@path)
        @logger.ok("")
      else
        @logger.fatal("No SIP found in #{@path}")
        @live = false
      end
    end
  end
end
