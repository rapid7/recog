require 'recog/verifier'
require 'recog/formatter'
require 'recog/verify_reporter'

module Recog
module VerifierFactory
  def self.build(options, db)
    formatter = Formatter.new(options, $stdout)
    reporter  = VerifyReporter.new(options, formatter, db.path)
    Verifier.new(db, reporter)
  end
end
end
