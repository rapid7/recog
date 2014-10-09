require 'recog/db'

describe Recog::DB do
  Dir[File.expand_path File.join('xml', '*.xml')].each do |xml_file_name|

    describe "##{File.basename(xml_file_name)}" do

      db = Recog::DB.new(xml_file_name)

      it "has a match key" do
        expect(db.match_key).not_to be_nil
        expect(db.match_key).not_to be_empty
      end

      db.fingerprints.each_index do |i|
        fp = db.fingerprints[i]

        context "#{fp.regex}" do

          if fp.name.nil? || fp.name.empty?
            skip "has a name"
          end

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
          # it "has test cases" do
          #  expect(fp.tests.length).not_to equal(0)
          # end

          fp.tests.each do |example|
            it "Example '#{example.content}' matches this regex" do
              match = fp.match(example.content)
              expect(match).to_not be_nil, 'Regex did not match'
              # test any extractions specified in the example
              example.attributes.each_pair do |k,v|
                expect(match[k]).to eq(v), "Regex didn't extracted expected value for fingerprint attribute #{k}"
              end
            end

            it "Example '#{example.content}' matches this regex first" do
              db.fingerprints.slice(0, i).each_index do |previous_i|
                prev_fp = db.fingerprints[previous_i]
                prev_fp.tests.each do |prev_example|
                  match = prev_fp.match(example.content)
                  expect(match).to be_nil, "Matched regex ##{previous_i} (#{db.fingerprints[previous_i].regex}) rather than ##{i} (#{db.fingerprints[i].regex})"
                end
              end
            end
          end

        end
      end

    end
  end
end
