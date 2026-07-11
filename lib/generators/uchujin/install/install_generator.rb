# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module Uchujin
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Install Uchujin: copy migrations and create an initializer"

      def self.next_migration_number(dirname)
        next_number = Time.now.utc.strftime("%Y%m%d%H%M%S")
        # Ensure uniqueness if multiple migrations are generated in the same second
        if Dir.exist?(dirname)
          while Dir.glob("#{dirname}/#{next_number}*").any?
            next_number = (next_number.to_i + 1).to_s
          end
        end
        next_number
      end

      def copy_migrations
        migration_template(
          "create_uchujin_tables.rb.tt",
          "db/migrate/create_uchujin_tables.rb"
        )
      end

      def create_initializer
        template "initializer.rb.tt", "config/initializers/uchujin.rb"
      end

      def mount_engine
        route 'mount Uchujin::Engine => "/uchujin"'
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
