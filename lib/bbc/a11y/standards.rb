require 'bbc/a11y/standards/content_follows_headings'
require 'bbc/a11y/standards/exactly_one_main_heading'
require 'bbc/a11y/standards/exactly_one_main_landmark'
require 'bbc/a11y/standards/heading_hierarchy'
require 'bbc/a11y/standards/tab_index'

module BBC
  module A11y
    module Standards
      def self.for(page_settings)
        all.reject { |standard|
          page_settings.skip_standard?(standard)
        }
      end

      def self.matching(name)
        all.select { |standard|
          name.match(standard.name)
        }
      end

      def self.all
        [
          ContentFollowsHeadings,
          HeadingHierarchy,
          ExactlyOneMainHeading,
          ExactlyOneMainLandmark,
          TabIndex
        ]
      end
    end
  end
end
