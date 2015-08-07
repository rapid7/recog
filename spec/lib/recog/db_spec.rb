require 'recog/db'

describe Recog::DB do
  let(:xml_file) { File.expand_path File.join('spec', 'data', 'test_fingerprints.xml') }
  subject { Recog::DB.new(xml_file) }

  describe "#fingerprints" do
    subject(:fingerprints) { described_class.new(xml_file).fingerprints }

    it { is_expected.to be_a(Enumerable) }

    context "with only a pattern" do
      subject(:entry) { described_class.new(xml_file).fingerprints[0] }

      it "has a blank name with no description" do
        expect(entry.name).to be_empty
      end

      it "has a pattern" do
        expect(entry.regex.source).to eq(".*\\(iSeries\\).*")
      end

      it "has no params" do
        expect(entry.params).to be_empty
      end

      it "has no tests" do
        expect(entry.tests).to be_empty
      end
    end

    context "with params" do
      subject(:entry) { described_class.new(xml_file).fingerprints[1] }

      it "has a name" do
        expect(entry.name).to eq('PalmOS')
      end

      it "has a pattern" do
        expect(entry.regex.source).to eq(".*\\(PalmOS\\).*")
      end

      it "has params" do
        expect(entry.params).to eq({"os.vendor"=>[1, "Palm"], "os.device"=>[2, "General"]})
      end

      it "has no tests" do
        expect(entry.tests).to be_empty
      end
    end

    context "with test" do
      subject(:entry) { described_class.new(xml_file).fingerprints[3] }

      it "has a name" do
        expect(entry.name).to eq('HP JetDirect Printer')
      end

      it "has a pattern" do
        expect(entry.regex.source).to eq("(?i:laserjet (.*)(?: series)?)")
      end

      it "has params" do
        expect(entry.params).to eq({"service.vendor"=>[0, "HP"]})
      end

      it "has no tests" do
        expect(entry.tests.map(&:content)).to match_array(["HP LaserJet 4100 Series", "HP LaserJet 2200"])
      end
    end
  end
end
