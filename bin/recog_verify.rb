#!/usr/bin/env ruby

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'optparse'
require 'ostruct'
require 'recog/fingerprint_db'
require 'recog/verifier_factory'

options = OpenStruct.new(color: false, detail: false)

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] XML_FINGERPRINTS_FILE"
  opts.separator "Verifies that each fingerprint passes its internal tests."
  opts.separator ""
  opts.separator "Options"

  opts.on("-f", "--format FORMATTER", 
          "Choose a formatter.",
          "  [s]ummary (default - failure/warning msgs and summary)",
          "  [d]etail  (fingerprint name with tests and expanded summary)") do |format|
    if format.start_with? 'd'
      options.detail = true
    end
  end

  opts.on("-c", "--color", "Enable color in the output.") do
    options.color = true
  end

  opts.on("-h", "--help", "Show this message.") do
    puts opts
    exit
  end
end
option_parser.parse!(ARGV)

if ARGV.count != 1
  puts option_parser
  exit
end

ndb = Recog::FingerprintDB.new("placeholder", ARGV.shift)
options.fingerprints = ndb.fingerprints
verifier = Recog::VerifierFactory.build(options)
verifier.verify_tests
