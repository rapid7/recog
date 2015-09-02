describe 'recog_match', type: :aruba do
  context 'when input data should match' do
    before(:each) do
      run 'recog_match ../../spec/data/matching_banners_fingerprints.xml ../../spec/data/banners.xml'
    end

    it 'produces correct output' do
      expect(last_command_started).to have_output_on_stdout /MATCH/
    end

    it 'exits correct' do
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context 'when input data should not match' do
    before(:each) do
      run 'recog_match ../../spec/data/failing_banners_fingerprints.xml ../../spec/data/banners.xml'
    end

    it 'produces correct output' do
      expect(last_command_started).to have_output_on_stdout /FAIL/
    end

    it 'exits correct' do
      # XXX: this should not be 0 -- makes using this tool for UNIX-y automation things hard
      expect(last_command_started).to have_exit_status(0)
    end
  end
end
