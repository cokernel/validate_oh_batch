#!/usr/bin/env ruby

libdir = File.expand_path(File.join('..', 'lib'), File.dirname(__FILE__))
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include? libdir

require 'rubygems'
require 'bundler/setup'
require 'trollop'
require 'oh_sip'

options = Trollop::options do
  opt :pwd, "Present working directory (you do not need to set this).", :type => :string, :required => true
  opt :batch, "Location of batch directory.  The program will infer this if possible.  Use this option if you want to validate an entire batch of SIPs.", :type => :string
  opt :sips_dir, "Location of SIPs directory.  Use this option if the SIPs directory is in a nonstandard location.", :type => :string
  opt :sip, "Location of a single SIP directory.  Use this option if you want to validate a single SIP within a batch.", :type => :string
  opt :list_tests, "List available validation tests.  Don't actually run tests.", :default => false
  opt :report_passes, "Include passing tests in log.", :default => false
  opt :check_fixity, "Check fixity of master files.", :default => false
  # development only
  opt :ignore_filename_errors, "Ignore filename errors.", :default => false
end

handler = OhSip::Handler.new options
handler.run
