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
            expected_capture_positions = fp.params.values.map(&:first).map(&:to_i)
            if fp.params.empty? && expected_capture_positions.size > 0
              fail "Non-asserting fingerprint with regex #{fp.regex} captures #{expected_capture_positions.size} time(s); 0 are needed"
            else
              # the actual captures that the regex will actually extract given matching input
              actual_captures = Regexp::Scanner.scan(fp.regex).select do |token_parts|
                token_parts.first == :group  && ![:close, :passive].include?(token_parts[1])
              end
              captures_size = actual_captures.size
              if captures_size > 0
                max_pos = expected_capture_positions.max
                # if it is actually looking to extract, ensure that there is enough to extract
                if max_pos > 0 && captures_size < max_pos
                  fail "Regex #{fp.regex} only has #{captures_size} captures; cannot extract from position #{max_pos}"
                end
                # if there is not capture but capturing is happening, fail since this is a waste
                if captures_size > max_pos
                  fail "Regex #{fp.regex} captures #{captures_size - max_pos} too many (#{captures_size} vs #{max_pos})"
                end
              end
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
