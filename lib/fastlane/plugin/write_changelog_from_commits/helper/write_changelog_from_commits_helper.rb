require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class WriteChangelogFromCommitsHelper
      # class methods that you define here become available in your action
      # as `Helper::WriteChangelogFromCommitsHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the write_changelog_from_commits plugin helper!")
      end
    end
  end
end
