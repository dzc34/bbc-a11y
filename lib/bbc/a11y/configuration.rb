require 'pathname'

module BBC
  module A11y

    def self.configure(&block)
      Configuration::DSL.new(block).settings
    end

    # TODO: add tests for this?
    def self.configure_from_file(filename)
      Configuration::DSL.new(File.read(filename), filename).settings
    rescue Errno::ENOENT
      raise Configuration::MissingConfigurationFileError.new
    end

    module Configuration
      def self.parse(filename)
        BBC::A11y.configure_from_file(filename)
      end

      def self.for_urls(urls)
        page_settings = urls.map { |url| PageSettings.new(url) }
        Settings.new.with_pages(page_settings)
      end

      MissingConfigurationFileError = Class.new(StandardError) do
        def message
          "Missing configuration file (a11y.rb).\n\n" +
          "Please visit http://www.rubydoc.info/gems/bbc-a11y " +
          "for more information."
        end
      end

      ParseError = Class.new(StandardError) do
        def message
           file, line = backtrace.first.split(":")[0..1]
           file = Pathname.new(file).relative_path_from(Pathname.new(Dir.pwd))
           line = line.to_i
           source_snippet = File.read(file).lines.each_with_index.map { |content, index|
             indent = (index == line - 1) ? "=> " : "   "
             indent + content
           }[line - 2..line]

           [
             "There was an error reading your configuration file at line #{line} of '#{file}'",
             "",
             source_snippet,
             "",
             super,
             "",
             "For help learning the configuration DSL, please visit https://github.com/cucumber-ltd/bbc-a11y"
           ]
        end
      end

      class Settings
        attr_reader :before_all_hooks,
          :after_all_hooks,
          :pages

        def initialize(before_all_hooks = [], after_all_hooks = [], pages = [])
          @before_all_hooks = before_all_hooks
          @after_all_hooks = after_all_hooks
          @pages = pages
          freeze
        end

        def with_pages(new_pages)
          self.class.new(before_all_hooks, after_all_hooks, new_pages)
        end
      end

      class PageSettings
        attr_reader :url
        attr_reader :skipped_standards

        def initialize(url, skipped_standards=[])
          @url = url
          @skipped_standards = skipped_standards
          freeze
        end

        def merge(other)
          self.class.new(url, skipped_standards + other.skipped_standards)
        end

        def skip_standard?(standard)
          @skipped_standards.any? { |pattern|
            pattern.match(standard.name)
          }
        end
      end

      class DSL
        attr_reader :settings

        def initialize(config, config_filename = nil)
          @settings = Settings.new
          @general_page_settings = []
          begin
            if config_filename
              instance_eval config, config_filename
            else
              instance_eval &config
            end
          rescue NoMethodError => error
            method_name = error.message.scan(/\`(.*)'/)[0][0]
            raise Configuration::ParseError, "`#{method_name}` is not part of the configuration language", error.backtrace
          rescue => error
            raise Configuration::ParseError, error.message, error.backtrace
          end
          @settings = settings.with_pages(apply_general_settings(settings.pages))
        end

        def before_all(&block)
          settings.before_all_hooks << block
        end

        def after_all(&block)
          settings.after_all_hooks << block
        end

        def page(url, &block)
          settings.pages << PageDSL.new(url, block).settings
        end

        def for_pages_matching(url, &block)
          @general_page_settings << PageDSL.new(url, block).settings
        end

        private

        def apply_general_settings(all_page_settings)
          all_page_settings.map { |page_settings|
            matching_general_settings = @general_page_settings.select { |general_page_settings| general_page_settings.url.match page_settings.url }
            matching_general_settings.reduce(page_settings) { |page_settings, general_page_settings|
              page_settings.merge(general_page_settings)
            }
          }
        end
      end

      class PageDSL
        attr_reader :settings

        def initialize(url, block)
          @settings = PageSettings.new(url)
          instance_eval &block if block
        end

        def skip_standard(pattern)
          @settings.skipped_standards << pattern
        end

      end

    end

  end
end
