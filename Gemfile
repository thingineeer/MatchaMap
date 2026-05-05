# Gemfile — fastlane 의존성 관리.
# 사용법: `bundle install` → `bundle exec fastlane <lane>`.
# Ruby 3.x 권장. `.ruby-version` 또는 chruby/rbenv로 고정.

source "https://rubygems.org"

gem "fastlane"

# fastlane 플러그인 (fastlane/Pluginfile에서 정의)
plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
