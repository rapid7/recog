require 'spec_helper'
require 'recog/fingerprint/regexp_factory'

describe Recog::Fingerprint::RegexpFactory do
  describe '.build' do
    subject { described_class.build(pattern, options) }

    let(:pattern) { 'Apache/(\d+)' }
    let(:options) { [ 'REG_ICASE' ] }

    specify do
      expect(subject).to be_a(::Regexp)
    end

    specify do
      expect(subject).to match('Apache/2')
    end

  end
end

