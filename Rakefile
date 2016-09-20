require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'

namespace :all do

  desc "Run specs against all Ruby #{RUBY_VERSION} gemfiles"
  task :spec do
    TestMatrix.each do
      system("bundle exec rspec spec")
    end
  end

  desc "Bundle all Ruby #{RUBY_VERSION} gemfiles"
  task :install do
    TestMatrix.each do
      system('bundle install')
    end
  end

  desc "Bundle all Ruby #{RUBY_VERSION} gemfiles"
  task :update do
    TestMatrix.each do
      system('bundle update')
    end
  end

end

class TestMatrix
  class << self

    COLOR_HEAD = "\e[44m"
    COLOR_WARNING = "\e[33m"
    COLOR_WARNING_HEAD = "\e[43m"
    COLOR_SUCCESS = "\e[32m"
    COLOR_FAILURE = "\e[31m"
    COLOR_FAILURE_HEAD = "\e[41m"
    COLOR_RESET = "\e[0m"

    def each(&block)
      succeeded_gemfiles = []
      failed_gemfiles = []
      skipped_gemfiles = []

      puts

      entries.each do |entry|
        gemfile = entry['gemfile']
        if compatible?(entry)

          puts tint(gemfile, COLOR_HEAD)
          puts
          ENV['BUNDLE_GEMFILE'] = gemfile
          if block.call
            succeeded_gemfiles << gemfile
          else
            failed_gemfiles << gemfile
          end
        else
          skipped_gemfiles << gemfile
        end
      end

      unless skipped_gemfiles.empty?
        puts tint("Skipped gemfiles incompatible with Ruby #{RUBY_VERSION}", COLOR_WARNING_HEAD)
        puts

        skipped_gemfiles.each do |gemfile|
          puts tint("- #{gemfile}", COLOR_WARNING)
        end
        puts
      end

      if failed_gemfiles.empty?
        puts
        puts tint('All gemfiles succeeded', COLOR_SUCCESS)
        puts
      else
        puts tint('Failed gemfiles', COLOR_FAILURE_HEAD)
        puts
        failed_gemfiles.each do |gemfile|
          puts tint("- #{gemfile}", COLOR_FAILURE)
        end
        puts

        fail 'Task failed for some gemsets'

      end

    end

    private

    def tint(message, color)
      color + message + COLOR_RESET
    end

    def compatible?(entry)
      entry['rvm'] == RUBY_VERSION
    end

    def entries
      require 'yaml'
      YAML.load_file('.travis.yml')['matrix']['include']
    end

  end
end


# def for_each_gemfile
#   version = ENV['VERSION'] || '*'
#   failed_gemfiles = []
#
#
#
#   Dir["gemfiles/Gemfile.#{version}"].sort.each do |gemfile|
#     next if gemfile =~ /.lock/
#     puts '', "\033[44m#{gemfile}\033[0m", ''
#     ENV['BUNDLE_GEMFILE'] = gemfile
#     unless yield
#       failed_gemfiles << gemfile
#     end
#   end
#
# end
