require "fastlane/action"

describe Fastlane::Actions::WriteChangelogFromCommitsAction do
  describe "#run" do
    before(:each) {
      expect(Fastlane::Actions).to receive(:git_log_between).and_return(log_messages)
      allow(File).to receive(:open)
    }

    context "when passing both commit_prefixes and other" do
      subject {
        described_class.run(
          path: "./",
          quiet: "true",
          commit_prefixes: "fixed, added",
          additional_section_name: "other",
          changelog_dir: "test_dir",
          version_code: "101",
        )
      }

      context "when all sections present in logs" do
        let(:log_messages) {
          <<~MSG
            Fixed random bug
            fixed other bug
            Added new feature
            Fixed final bug
            added second feature
            Do other thing
          MSG
        }

        let(:expected_release_notes) {
          <<~MSG
            <u>Fixed</u>
            Random bug
            Other bug
            Final bug

            <u>Added</u>
            New feature
            Second feature

            <u>Other</u>
            Do other thing

          MSG
        }

        it "formats the git logs with correct sections" do
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
            fixed final bug
            Do other thing
          MSG
        }

        let(:expected_release_notes) {
          <<~MSG
            <u>Fixed</u>
            Random bug
            Other bug
            Final bug

            <u>Other</u>
            Do other thing

          MSG
        }

        it "formats the git logs with correct sections" do
          expect(subject).to eq(expected_release_notes)
        end
      end

      context "when no logs" do
        let(:log_messages) { "" }

        it "raises an error" do
          expect { subject }.to raise_error("No logs found since last tag")
        end
      end
    end

    context "when passing only commit_prefixes" do
      subject {
        described_class.run(
          path: "./",
          quiet: "true",
          commit_prefixes: "fixed, added",
          changelog_dir: "test_dir",
          version_code: "101",
        )
      }

      let(:log_messages) {
        <<~MSG
          Fixed random bug
          fixed other bug
          Added new feature
          Fixed final bug
          added second feature
          Do other thing
        MSG
      }

      let(:expected_release_notes) {
        <<~MSG
          <u>Fixed</u>
          Random bug
          Other bug
          Final bug

          <u>Added</u>
          New feature
          Second feature

        MSG
      }

      it "only logs prefixed lines" do
        expect(subject).to eq(expected_release_notes)
      end
    end

    context "when passing only additional_section_name" do
      subject {
        described_class.run(
          path: "./",
          quiet: "true",
          additional_section_name: "other",
          changelog_dir: "test_dir",
          version_code: "101",
        )
      }

      let(:log_messages) {
        <<~MSG
          Fixed random bug
          fixed other bug
          Added new feature
          Fixed final bug
          added second feature
          Do other thing
        MSG
      }

      let(:expected_release_notes) {
        <<~MSG
          <u>Other</u>
          Fixed random bug
          Fixed other bug
          Added new feature
          Fixed final bug
          Added second feature
          Do other thing

        MSG
      }

      it "logs everything to additional_section_name" do
        expect(subject).to eq(expected_release_notes)
      end
    end

    context "when read_only is true" do
      subject {
        described_class.run(
          path: "./",
          quiet: "true",
          commit_prefixes: "fixed, added",
          additional_section_name: "other",
          changelog_dir: "test_dir",
          version_code: "101",
          read_only: "true",
        )
      }

      let(:log_messages) {
        <<~MSG
          Fixed random bug
          fixed other bug
          Added new feature
          Fixed final bug
          added second feature
          Do other thing
        MSG
      }

      let(:expected_release_notes) {
        <<~MSG
          <u>Fixed</u>
          Random bug
          Other bug
          Final bug

          <u>Added</u>
          New feature
          Second feature

          <u>Other</u>
          Do other thing

        MSG
      }

      it "does not write contents to file" do
        file = instance_double(File)
        expect(File).not_to receive(:open).with("test_dir/101.txt", "w")

        expect(subject).to eq(expected_release_notes)
      end
    end
  end
end
