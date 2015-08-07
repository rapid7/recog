require 'recog/db'
require 'regexp_parser'

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

          it "has a name" do
            expect(fp.name).not_to be_nil
            expect(fp.name).not_to be_empty
          end

          it "has a regex" do
            expect(fp.regex).not_to be_nil
            expect(fp.regex.class).to be ::Regexp
          end

          it 'uses capturing regular expressions properly' do
            # the list of index-based captures that the fingerprint is expecting
            expected_capture_positions = fp.params.values.map(&:first).map(&:to_i).select { |position| position > 0 }
            if fp.params.empty? && expected_capture_positions.size > 0
              fail "Non-asserting fingerprint with regex #{fp.regex} captures #{expected_capture_positions.size} time(s); 0 are needed"
            else
              # parse the regex and count the number of captures
              actual_capture_positions = []
              capture_number = 1
              Regexp::Scanner.scan(fp.regex).each do |token_parts|
                if token_parts.first == :group  && ![:close, :options, :passive].include?(token_parts[1])
                  actual_capture_positions << capture_number
                  capture_number += 1
                end
              end
              # compare the captures actually performed to those being used and ensure that they contain
              # the same elements regardless of order, preventing, over-, under- and other forms of mis-capturing.
              actual_capture_positions = actual_capture_positions.sort.uniq
              expected_capture_positions = expected_capture_positions.sort.uniq
              expect(actual_capture_positions).to eq(expected_capture_positions),
                "Regex didn't capture (#{actual_capture_positions}) exactly what fingerprint extracted (#{expected_capture_positions})"
            end
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
                expect(match[k]).to eq(v), "Regex didn't extract expected value for fingerprint attribute #{k} -- got #{match[k]} instead of #{v}"
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
