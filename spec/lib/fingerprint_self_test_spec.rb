# frozen_string_literal: true

require 'recog/db'
require 'regexp_parser'
require 'nokogiri'

describe Recog::DB do
  let(:schema) { Nokogiri::XML::Schema(open(File.join(FINGERPRINT_DIR, 'fingerprints.xsd'))) }
  Dir[File.join(FINGERPRINT_DIR, '*.xml')].each do |xml_file_name|
    describe "##{File.basename(xml_file_name)}" do
      it 'is valid XML' do
        doc = Nokogiri::XML(open(xml_file_name))
        errors = schema.validate(doc)
        expect(errors).to be_empty, "#{xml_file_name} is invalid recog XML -- #{errors.inspect}"
      end

      db = Recog::DB.new(xml_file_name)

      it 'has a match key' do
        expect(db.match_key).not_to be_nil
        expect(db.match_key).not_to be_empty
      end

      it "has valid 'preference' value" do
        # Reserve values below 0.10 and above 0.90 for users
        # See xml/fingerprints.xsd
        expect(db.preference.class).to be ::Float
        expect(db.preference).to be_between(0.10, 0.90)
      end

      fp_descriptions = []
      db.fingerprints.each_index do |i|
        fp = db.fingerprints[i]

        it "doesn't have a duplicate description" do
          raise "'#{fp.name}'s description is not unique" if fp_descriptions.include?(fp.name)

          fp_descriptions << fp.name
        end

        context fp.name.to_s do
          param_names = []
          it 'has consistent os.device and hw.device' do
            raise "#{fp.name} has both hw.device and os.device but with differing values" if fp.params['os.device'] && fp.params['hw.device'] && (fp.params['os.device'] != fp.params['hw.device'])
          end
          fp.params.each do |param_name, pos_value|
            pos, value = pos_value
            it 'has valid looking fingerprint parameter names' do
              raise "'#{param_name}' is invalid" unless param_name =~ /^(?:cookie|[^.]+\..*)$/
            end

            it "doesn't have param values for capture params" do
              raise "'#{fp.name}'s #{param_name} is a non-zero pos but specifies a value of '#{value}'" if pos > 0 && !value.to_s.empty?
            end

            it 'has *.device parameter values other than General, Server or Unknown, which are not helpful' do
              raise "'#{param_name}' has unhelpful value '#{value}'" if pos == 0 && param_name =~ /^(?:[^.]+\.device*)$/ && value =~ /^(?i:general|server|unknown)$/
            end

            it "doesn't omit values for non-capture params" do
              raise "'#{fp.name}'s #{param_name} is not a capture (pos=0) but doesn't specify a value" if pos == 0 && value.to_s.empty?
            end

            it "doesn't have duplicate params" do
              raise "'#{fp.name}'s has duplicate #{param_name}" if param_names.include?(param_name)

              param_names << param_name
            end

            it 'uses interpolation correctly' do
              raise "'#{fp.name}' uses interpolated value '#{interpolated}' that does not exist" if pos == 0 && /\{(?<interpolated>[^\s{}]+)\}/ =~ value && !fp.params.key?(interpolated)
            end
          end
        end

        context fp.regex.to_s do
          it 'has a valid looking name' do
            expect(fp.name).not_to be_nil
            expect(fp.name).not_to be_empty
          end

          it 'has a regex' do
            expect(fp.regex).not_to be_nil
            expect(fp.regex.class).to be ::Regexp
          end

          it 'uses capturing regular expressions properly' do
            # the list of index-based captures that the fingerprint is expecting
            expected_capture_positions = fp.params.values.map(&:first).map(&:to_i).select { |position| position > 0 }
            raise "Non-asserting fingerprint with regex #{fp.regex} captures #{expected_capture_positions.size} time(s); 0 are needed" if fp.params.empty? && expected_capture_positions.size > 0

            # parse the regex and count the number of captures
            actual_capture_positions = []
            capture_number = 1
            Regexp::Scanner.scan(fp.regex).each do |token_parts|
              if token_parts.first == :group && !%i[close passive options options_switch].include?(token_parts[1])
                actual_capture_positions << capture_number
                capture_number += 1
              end
            end
            # compare the captures actually performed to those being used and ensure that they contain
            # the same elements regardless of order, preventing, over-, under- and other forms of mis-capturing.
            actual_capture_positions = actual_capture_positions.sort.uniq
            expected_capture_positions = expected_capture_positions.sort.uniq
            expect(actual_capture_positions).to eq(expected_capture_positions),
                                                "Regex has #{actual_capture_positions.size} capture groups, but the fingerprint expected #{expected_capture_positions.size} extractions."
          end

          # Not yet enforced
          # it "has test cases" do
          #  expect(fp.tests.length).not_to equal(0)
          # end

          it 'Has a reasonable number (<= 20) of test cases' do
            expect(fp.tests.length).to be <= 20
          end

          fp_examples = []
          fp.tests.each do |example|
            it "doesn't have a duplicate examples" do
              raise "'#{fp.name}' has duplicate example '#{example.content}'" if fp_examples.include?(example.content)

              fp_examples << example.content
            end
            it "Example '#{example.content}' matches this regex" do
              match = fp.match(example.content)
              expect(match).to_not be_nil, 'Regex did not match'
              # test any extractions specified in the example
              example.attributes.each_pair do |k, v|
                next if k == '_encoding'
                next if k == '_filename'

                expect(match[k]).to eq(v),
                                    "Regex didn't extract expected value for fingerprint attribute #{k} -- got #{match[k]} instead of #{v}"
              end
            end

            it "Example '#{example.content}' matches this regex first" do
              db.fingerprints.slice(0, i).each_index do |previous_i|
                prev_fp = db.fingerprints[previous_i]
                prev_fp.tests.each do |_prev_example|
                  match = prev_fp.match(example.content)
                  expect(match).to be_nil,
                                   "Matched regex ##{previous_i} (#{db.fingerprints[previous_i].regex}) rather than ##{i} (#{db.fingerprints[i].regex})"
                end
              end
            end
          end
        end
      end
    end
  end
end
