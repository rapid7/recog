describe 'recog_verify', type: :aruba do
  context 'when there are no tests' do
    before(:each) do
      run 'recog_verify ../../spec/data/no_tests.xml'
    end

    it 'produces correct output' do
      expect(last_command_started).to have_output_on_stdout /SUMMARY: Test completed with 0 successful, 0 warnings, and 0 failures/
    end

    it 'exits correct' do
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context 'when there are tests' do
    context 'without issues' do
      before(:each) do
        run 'recog_verify ../../spec/data/successful_tests.xml'
      end

      it 'produces correct output' do
        expect(last_command_started).to have_output_on_stdout /SUMMARY: Test completed with 4 successful, 0 warnings, and 0 failures/
      end

      it 'exits correct' do
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context 'with warnings' do
      before(:each) do
        run 'recog_verify ../../spec/data/tests_with_warnings.xml'
      end

      it 'produces correct output' do
        expect(last_command_started).to have_output_on_stdout /WARN: 'Pure-FTPd' has no test cases/
        expect(last_command_started).to have_output_on_stdout /SUMMARY: Test completed with 1 successful, 1 warnings, and 0 failures/
      end

      it 'exits correct' do
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context 'with failures' do
      before(:each) do
        run 'recog_verify ../../spec/data/tests_with_failures.xml'
      end

      it 'produces correct output' do
        expect(last_command_started).to have_output_on_stdout /FAIL: 'foo test' failed to match "bar" with '\(\?-mix:\^foo\$\)'/
        expect(last_command_started).to have_output_on_stdout /FAIL: '' failed to match "This almost matches" with '\(\?-mix:\^This matches\$\)'/
        expect(last_command_started).to have_output_on_stdout /FAIL: 'bar test' failed to find expected capture group os.version '5.0'/
        expect(last_command_started).to have_output_on_stdout /SUMMARY: Test completed with 0 successful, 0 warnings, and 3 failures/
      end

      it 'exits correct' do
        expect(last_command_started).to have_exit_status(0)
      end
    end
  end
end
