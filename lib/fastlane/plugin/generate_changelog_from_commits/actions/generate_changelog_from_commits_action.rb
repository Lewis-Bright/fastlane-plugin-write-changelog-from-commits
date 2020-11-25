require 'fastlane/action'
require_relative '../helper/generate_changelog_from_commits_helper'

module Fastlane
  module Actions
    class GenerateChangelogFromCommitsAction < Action
      OTHER_SECTION = "Other"

      def self.run(params)
        from = Actions.last_git_tag_name
        UI.verbose("Found the last Git tag: #{from}")
        to = 'HEAD'

        if params[:path].nil?
          UI.message("No path provided, using default at '/'")
          params[:path] = './' unless params[:path]
        end

        params[:commit_prefixes] ||= []

        Dir.chdir(params[:path]) do
          changelog = Actions.git_log_between("%B", from, to, nil, nil, nil)
          changelog = changelog.gsub("\n\n", "\n") if changelog # as there are duplicate newlines
          raise "No logs found since last tag" if changelog.strip.empty?

          raw_release_notes = create_raw_release_notes(changelog, params[:commit_prefixes])

          release_notes = create_release_notes(raw_release_notes)
          Actions.lane_context[SharedValues::FL_CHANGELOG] = release_notes
          if params[:quiet] == false
            UI.message(release_notes)
          end

          if params[:version_code]
            write_release_notes(release_notes, params[:version_code], params[:changelog_dir])
          else
            UI.message("No version code provided, so could not write file")
          end
          release_notes
        end
      end

      def self.create_raw_release_notes(changelog, commit_prefixes)
        raw_release_notes = commit_prefixes.to_h { |p| [p.capitalize, []] }
        raw_release_notes[OTHER_SECTION] = []
        changelog.each_line do |line|
          section_exists = false
          commit_prefixes.each do |prefix|
            next unless line.downcase.start_with?(prefix.downcase)

            raw_release_notes[prefix.capitalize] << line.slice(prefix.length..line.length).strip
            section_exists = true
            break
          end
          raw_release_notes[OTHER_SECTION] << line.strip unless section_exists
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
        "Generates a changelog file by pattern matching on git commits since the last tag."
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
            env_name: 'GENERATE_CHANGELOG_FROM_COMMITS_PATH',
            description: 'Path of the git repository',
            optional: true,
            default_value: './'
          ),
          FastlaneCore::ConfigItem.new(
            key: :quiet,
            env_name: 'GENERATE_CHANGELOG_FROM_COMMITS_TAG_QUIET',
            description: 'Whether or not to disable changelog output',
            optional: true,
            default_value: false,
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :changelog_dir,
            env_name: 'GENERATE_CHANGELOG_FROM_COMMITS_CHANGELOG_DIR',
            description: 'Path to write new changelogs',
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit_prefixes,
            env_name: "GENERATE_CHANGELOG_FROM_COMMITS_PREFIXES",
            description: "List of prefixes to group in the changelog",
            type: Array,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :version_code,
            env_name: "GENERATE_CHANGELOG_FROM_COMMITS_VERSION_CODE",
            description: "Version code used to create file",
            optional: true
          )
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
