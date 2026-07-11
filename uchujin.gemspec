# frozen_string_literal: true

require_relative "lib/uchujin/version"

Gem::Specification.new do |spec|
  spec.name        = "uchujin"
  spec.version     = Uchujin::VERSION
  spec.authors     = [ "Cody Baldwin" ]
  spec.email       = [ "codybaldwin@gmail.com" ]
  spec.homepage    = "https://github.com/cmbaldwin/Uchujin"
  spec.summary     = "Drop-in, single-project error tracker for Rails"
  spec.description = "In-process error capture and monitoring for Rails apps. " \
                     "SolidQueue-backed processing, Tailwind + Hotwire admin UI, " \
                     "host-delegated auth, Kamal deploy/uptime tracking. No SaaS."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmbaldwin/Uchujin"
  spec.metadata["changelog_uri"] = "https://github.com/cmbaldwin/Uchujin/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "rails", ">= 7.1"
  # SolidQueue is provided by the host app; we don't hard-require it so hosts on
  # Sidekiq/async can still enqueue ActiveJob. Capture jobs use ActiveJob.
end
