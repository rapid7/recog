require_relative '../../lib/recog'
require 'yaml'

describe Recog::Nizer do
  subject { Recog::Nizer }

  describe "#match" do
    File.readlines(File.expand_path(File.join('spec', 'data', 'smb_native_os.txt'))).each do |line|
      data = line.strip
      context "with smb_native_os:#{data}" do
        let(:match_result) { subject.match('smb.native_os', data) }

        it "returns a hash" do
          expect(match_result.class).to eq(::Hash)
        end

        it "returns a successful match" do
          expect(match_result['matched']).to match(/^[A-Z]/)
        end

        it "correctly matches service or os" do
          if data =~ /^Windows/
            expect(match_result['os.product']).to match(/^Windows/)
          end

          if data =~ /^Samba/
            expect(match_result['service.product']).to match(/^Samba/)
          end
        end

      end
    end
  end

  describe "self.best_os_match" do

    # Demonstrates how this method picks up additional attributes from other members of the winning
    # os.product match group and applies them to the result.
    matches1 = YAML.load(File.read(File.expand_path(File.join('spec', 'data', 'os_best_match_1.yml'))))
    context "with os_best_match_1.yml" do
      let(:result) { subject.best_os_match(matches1) }

      it "returns a hash" do
        expect(result.class).to eq(::Hash)
      end

      it "matches Windows 2008" do
        expect(result['os.product']).to eq('Windows 2008')
      end

      it "matches Microsoft" do
        expect(result['os.vendor']).to eq('Microsoft')
      end

      it "matches English" do
        expect(result['os.language']).to eq('English')
      end

      it "matches service pack 2" do
        expect(result['os.version']).to eq('Service Pack 2')
      end
    end

    # Demonstrates how additive os.certainty values allow a 1.0 certainty rule to be overridden
    # by multiple lower certainty matches
    matches2 = YAML.load(File.read(File.expand_path(File.join('spec', 'data', 'os_best_match_2.yml'))))
    context "with os_best_match_2.yml" do
      let(:result) { subject.best_os_match(matches2) }

      it "returns a hash" do
        expect(result.class).to eq(::Hash)
      end

      it "matches Windows 2012" do
        expect(result['os.product']).to eq('Windows 2012')
      end

      it "matches Microsoft" do
        expect(result['os.vendor']).to eq('Microsoft')
      end

      it "matches Arabic" do
        expect(result['os.language']).to eq('Arabic')
      end

      it "matches service pack 1" do
        expect(result['os.version']).to eq('Service Pack 1')
      end
    end

  end


end
