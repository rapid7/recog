require 'nokogiri'
require 'recog/fingerprint'

describe Recog::Fingerprint do
  context "whitespace" do
    let(:xml) do
      path = File.expand_path(File.join('spec', 'data', 'whitespaced_fingerprint.xml'))
      doc = Nokogiri::XML(IO.read(path))
      doc.xpath("//fingerprint").first
    end
    subject { Recog::Fingerprint.new(xml) }

    describe "#name" do
      it "properly squashes whitespace" do
        expect(subject.name).to eq('I love whitespace!')
      end
    end
  end

  describe "#verification" do
    let(:xml_file) { File.expand_path(File.join('spec', 'data', 'verification_fingerprints.xml')) }
    let(:doc) { Nokogiri::XML(IO.read(xml_file)) }

    context "0 params" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[0]) }

      it "does not yield if a fingerprint has 0 parameters" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "0 capture groups" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[1]) }

      it "does not yield if a fingerprint has parameters, but 0 are defined by a capture group " do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "0 examples" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[2]) }

      it "does not yield if a fingerprint has 0 examples" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "1 capture group, 1 example" do

      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[3]) }

      it "does not yield when one capture group parameter is tested for in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "2 capture groups, 1 example" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[4]) }

      it "does not yield when two capture group parameters are tested for in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "2 capture groups, 2 examples, 1 in each" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[5]) }

      it "does not yield when two capture group parameters are tested for in two examples, one parameter in each" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.not_to yield_control
      end
    end

    context "1 missing capture group, 1 example" do

      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[6]) }

      it "identifies when a parameter defined by a capture group is not included in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.to yield_successive_args([:fail, String])
      end
    end

    context "2 missing capture groups, 1 example" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[7]) }

      it "identifies when two parameters defined by a capture groups are not included in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.to yield_successive_args([:fail, String], [:fail, String])
      end
    end

    context "1 missing capture group, 2 examples" do

      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[8]) }

      it "identifies when a parameter defined by a capture group is not included in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.to yield_successive_args([:fail, String])
      end
    end

    context "2 missing capture groups, 2 examples" do
      let(:entry) { described_class.new(doc.xpath("//fingerprints/fingerprint")[9]) }

      it "identifies when two parameters defined by a capture groups are not included in one example" do
        expect { |unused| entry.verify_tests_have_capture_groups(&unused) }.to yield_successive_args([:fail, String], [:fail, String])
      end
    end

  end

  skip  "value interpolation" do
    # TODO
  end
end
