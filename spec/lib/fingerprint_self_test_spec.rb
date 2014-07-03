require_relative '../../lib/recog/db'

describe Recog::DB do
  Dir[File.expand_path File.join('xml', '*.xml')].each do |xml_file_name|

    describe "##{File.basename(xml_file_name)}" do

      db = Recog::DB.new(xml_file_name)

      it "has a match key" do
        expect(db.match_key).not_to be_nil
        expect(db.match_key).not_to be_empty
      end

      db.fingerprints.each do |fp|

        context "#{fp.regex}" do

          # Not yet enforced
          # it "has a name" do
          #   expect(fp.name).not_to be_nil
          #   expect(fp.name).not_to be_empty
          # end

          it "has a regex" do
            expect(fp.regex).not_to be_nil
            expect(fp.regex.class).to be ::Regexp
          end

          # Not yet enforced
          # it "has a test cases" do
          #  expect(fp.tests.length).not_to equal(0)
          # end

          fp.tests.each do |example|
            it "passes self-test #{example.gsub(/\s+/, ' ')[0,32]}..." do
              expect(fp.regex.match(example)).to_not eq(nil)
            end
          end

        end
      end

    end
  end
end
