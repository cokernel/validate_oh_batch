require 'date'
require 'nokogiri'
require 'oh_sip/validator'

module OhSip
  class OhmsValidator
    include Validator

    def initialize options = nil
      set_default_options(options)
      @tests = [
        :ohms_is_valid_xml,
        :ohms_has_repository,
        :ohms_has_title,
        :ohms_has_source,
        :ohms_has_creators,
        :ohms_has_subjects,
        :ohms_has_publisher,
        :ohms_has_date,
        :ohms_date_is_ISO8601_or_American,
        :ohms_has_content_type,
        :ohms_has_accession_number,
        :ohms_has_description,
      ]
      if @options
        @base = File.basename(@options[:file])
      end
    end

    def ohms_has_description
      ohms_has_field('description')
    end

    def ohms_has_accession_number
      ohms_has_field('accession')
    end

    def ohms_has_content_type
      ohms_has_field('clip_format', 'content_type:clip_format')
    end

    def ohms_date_is_ISO8601_or_American
      date = @xml.xpath('//date').first.content
      if date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/
        year = $1.to_i
        month = $2.to_i
        day = $3.to_i
        if Date.valid_civil?(year, month, day)
          @logger.ok
        else
          @logger.warn("OHMS metadata file #{@base} uses invalid ISO8601 date #{date}")
        end
      elsif date =~ /^(\d\d)-(\d\d)-(\d\d\d\d)$/
        year = $3.to_i
        month = $1.to_i
        day = $2.to_i
        if Date.valid_civil?(year, month, day)
          @logger.ok
        else
          @logger.warn("OHMS metadata file #{@base} uses invalid American date #{date}")
        end
      else
        @logger.warn("OHMS metadata file #{@base} has non-ISO8601, non-American date format")
      end
    end

    def ohms_has_date
      ohms_has_field('date')
    end

    def ohms_has_publisher
      ohms_has_field('repository', 'publisher:repository')
    end

    def ohms_has_subjects
      ohms_has_field('subject')
    end

    def ohms_has_creators
      ohms_has_field('interviewee', 'creators:interviewee')
      ohms_has_field('interviewer', 'creators:interviewer')
    end

    def ohms_has_source
      ohms_has_field('series_name', 'source')
    end

    def ohms_has_title
      ohms_has_field('title')
    end

    def ohms_has_field(field, name=field)
      xpath = @xml.xpath("//#{field}")
      if xpath.count > 0 and xpath.first.content.length > 0
        @logger.ok
      else
        @logger.warn("OHMS: metadata file #{@base} is missing field #{name}")
      end
    end

    def ohms_has_repository
      ohms_has_field('repository')
    end

    def ohms_is_valid_xml
      begin
        @xml = Nokogiri::XML(IO.read @options[:file]) {|config| config.strict}
        @logger.ok
      rescue Nokogiri::XML::SyntaxError => e
        @logger.fatal("OHMS: metadata file #{@base} is invalid XML")
        @live = false
      end
    end
  end
end
