require "fastlane/action"
require_relative "../helper/write_changelog_from_commits_helper"

module Fastlane
  module Actions
    class WriteChangelogFromCommitsAction < Action
      def self.run(params)
        if params[:additional_section_name].nil? && params[:commit_prefixes].nil?
          raise "Please provide either 'additional_section_name' or 'commit_prefixes' to action"
        end

        from = Actions.last_git_tag_name
        UI.verbose("Found the last Git tag: #{from}")
        to = "HEAD"

        if params[:path].nil?
          UI.message("No path provided, using default at '/'")
          params[:path] = "./" unless params[:path]
        end

        params[:commit_prefixes] ||= []

        Dir.chdir(params[:path]) do
          changelog = Actions.git_log_between("%B", from, to, nil, nil, nil)
          changelog = changelog.gsub("\n\n", "\n") if changelog # as there are duplicate newlines
          raise "No logs found since last tag" if changelog.strip.empty?

          raw_release_notes = create_raw_release_notes(changelog, params[:commit_prefixes], params[:additional_section_name])

          release_notes = create_release_notes(raw_release_notes)
          Actions.lane_context[SharedValues::FL_CHANGELOG] = release_notes
          if params[:quiet] == false
            UI.message(release_notes)
          end

          if params[:version_code]
            write_release_notes(release_notes, params[:version_code], params[:changelog_dir]) unless params[:read_only]
          else
            UI.message("No version code provided, so could not write file")
          end
          release_notes
        end
      end

      def self.create_raw_release_notes(changelog, commit_prefixes, additional_section_name)
        raw_release_notes = commit_prefixes.to_h { |p| [p.capitalize, []] }
        raw_release_notes[additional_section_name.capitalize] = [] if additional_section_name
        changelog.each_line do |line|
          section_exists = false
          commit_prefixes.each do |prefix|
            next unless line.downcase.start_with?(prefix.downcase)

            raw_release_notes[prefix.capitalize] << line.slice(prefix.length..line.length).strip.capitalize
            section_exists = true
            break
          end
          if additional_section_name && !section_exists
            raw_release_notes[additional_section_name.capitalize] << line.strip.capitalize
          end
        end
        raw_release_notes
      end

      def self.create_release_notes(raw_release_notes)
        release_notes = ""
        raw_release_notes.keys.each do |section_title|
          next if raw_release_notes[section_title].empty?
          release_notes << "<u>#{section_title}</u>\n"
          release_notes << "#{raw_release_notes[section_title].join("\n")}\n\n"
        end
        release_notes
      end

      def self.write_release_notes(release_notes, version_code, changelog_dir)
        File.open(File.join(changelog_dir, "#{version_code}.txt"), "w") do |f|
          f.write(release_notes)
        end
        UI.message("Written release notes to #{version_code}.txt")
      end

      def self.description
        "Writes a changelog file by pattern matching on git commits since the last tag."
      end

      def self.authors
        ["Lewis Bright"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "This plugin will search through all of your commits since the last tag. It will pattern match on keywords at the beginning in order to generate different secions of the changelog (bugfix, feature etc). Then it will create a new file in the changelogs directory that is named after the current version, and write the contents of the changelog"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :path,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_PATH",
            description: "Path of the git repository",
            optional: true,
            default_value: "./",
          ),
          FastlaneCore::ConfigItem.new(
            key: :quiet,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_TAG_QUIET",
            description: "Whether or not to disable changelog output",
            optional: true,
            default_value: false,
            is_string: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :changelog_dir,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_CHANGELOG_DIR",
            description: "Path to write new changelogs",
            optional: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit_prefixes,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_PREFIXES",
            description: "List of prefixes to group in the changelog (omit to place all lines under additional_section_name)",
            type: Array,
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :additional_section_name,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_ADDITIONAL_SECTION",
            description: "Section to contain all other commit lines (omit if you only want to log lines beginning with prefixes)",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :version_code,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_VERSION_CODE",
            description: "Version code used to create file",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :read_only,
            env_name: "WRITE_CHANGELOG_FROM_COMMITS_READ_ONLY",
            description: "If true will simply return the changelog rather than writing it",
            optional: true,
            default_value: false,
            is_string: false,
          ),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
