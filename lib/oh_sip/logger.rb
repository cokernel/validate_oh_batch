require 'logger'

module OhSip
  class Logger
    def initialize options
      @options = options
      @logger = ::Logger.new @options[:output]
      @ok = 0
      @warn = 0
      @fatal = 0
    end

    # http://stackoverflow.com/a/5100339/237176
    def ok(message = nil)
      name = caller[0][/`.*'/][1..-2].gsub(/_/, ' ')
      if @options[:info]
        @logger.info "ok #{name}"
      end
      @ok += 1
    end

    def warn(message)
      name = caller[0][/`.*'/][1..-2].gsub(/_/, ' ')
      if @options[:warn]
        @logger.warn "not ok #{name} (#{message})"
      end
      @warn += 1
    end

    def fatal(message)
      name = caller[0][/`.*'/][1..-2].gsub(/_/, ' ')
      @logger.fatal "not ok #{name} (#{message})"
      @fatal += 1
    end

    def reportline(label, count, total)
      pct = (count * 100 / total).floor
      printf("%-13s: %4d (%3d)%%\n", label, count, pct)
    end

    def summarize
      total = @ok + @warn + @fatal
      puts
      reportline("Passing tests", @ok, total)
      reportline("Warnings", @warn, total)
      reportline("Failures", @fatal, total)
      reportline("Test count", total, total)
      puts
      if @ok < total
        puts "This is INVALID."
      else
        puts "This is VALID."
      end
    end
  end
end
