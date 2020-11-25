require 'fastlane/action'

describe Fastlane::Actions::GenerateChangelogFromCommitsAction do
  describe '#run' do
    subject { described_class.run(path: "./", quiet: "true", commit_prefixes: ["fixed","added"], changelog_dir: "test_dir", version_code: "101") }

    before(:each) {
      expect(Fastlane::Actions).to receive(:git_log_between).and_return(log_messages)
      allow(File).to receive(:open)
    }

    context "when all sections present in logs" do
      let(:log_messages) {
        <<~MSG
          Fixed random bug
          Fixed other bug
          Added new feature
          Fixed final bug
          Added second feature
          Do other thing
        MSG
      }

      let(:expected_release_notes) {
        <<~MSG
          <u>Fixed</u>
          random bug
          other bug
          final bug

          <u>Added</u>
          new feature
          second feature

          <u>Other</u>
          Do other thing

        MSG
      }

      it "formats the git logs with all sections" do
        expect(subject).to eq(expected_release_notes)
      end

      it "writes all contents to file" do
        file = instance_double(File)
        expect(File).to receive(:open).with("test_dir/101.txt", "w").and_yield(file)
        expect(file).to receive(:write).with(expected_release_notes)
        subject
      end
    end

    context "when one section missing" do
      let(:log_messages) {
        <<~MSG
          Fixed random bug
          Fixed other bug
          Fixed final bug
          Do other thing
        MSG
      }

      let(:expected_release_notes) {
        <<~MSG
          <u>Fixed</u>
          random bug
          other bug
          final bug

          <u>Other</u>
          Do other thing

        MSG
      }

      it "formats the git logs with all sections" do
        expect(subject).to eq(expected_release_notes)
      end
    end

    context "when no logs" do
      let(:log_messages) { "" }

      it "formats the git logs with all sections" do
        expect{subject}.to raise_error("No logs found since last tag")
      end
    end
  end
end
