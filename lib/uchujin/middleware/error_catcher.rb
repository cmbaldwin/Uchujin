# frozen_string_literal: true

module Uchujin
  module Middleware
    class ErrorCatcher
      def initialize(app)
        @app = app
      end

      def call(env)
        Uchujin::Breadcrumbs.clear!
        Uchujin::Context.clear!
        Uchujin::Breadcrumbs.add(type: "notice", message: "request.start")

        @app.call(env)
      rescue Exception => e
        unless Uchujin.ignored?(e)
          request = ActionDispatch::Request.new(env)
          Uchujin.notify(e, request: request, component: "web")
        end
        raise
      end
    end
  end
end
