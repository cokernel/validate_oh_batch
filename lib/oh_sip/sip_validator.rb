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
        :sip_has_ohms_metadata_file,
        :sip_has_valid_ohms_metadata_file,
      ]
      if @path
        @master = File.join @path, 'master'
      end
    end

    def ohms_filename
      File.join(@path, "#{@base}_ohm.xml")
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
      Find.find(@path) do |subpath|
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
      Find.find(@path) do |subpath|
        filename = File.basename(subpath)
        unless is_valid_format?(filename)
          @logger.warn("SIP #{@base}: filename #{subpath} has invalid characters")
          valid = false
        end
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
