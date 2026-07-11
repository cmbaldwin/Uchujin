# frozen_string_literal: true

module Uchujin
  # Parses Honeybadger-style search tokens:
  #   -is:resolved  -is:ignored  is:assigned  tag:foo  environment:production  free text
  class QueryParser
    Token = Struct.new(:key, :value, :negated, keyword_init: true)

    def initialize(query)
      @query = query.to_s.strip
    end

    def apply(scope)
      free_text = []
      tokens.each do |token|
        if token.key.nil?
          free_text << token.value
        else
          scope = apply_token(scope, token)
        end
      end
      free_text.reject!(&:blank?)
      if free_text.any?
        q = "%#{free_text.join(' ').downcase}%"
        scope = scope.where("LOWER(class_name) LIKE ? OR LOWER(message) LIKE ?", q, q)
      end
      scope
    end

    def tokens
      @tokens ||= begin
        list = []
        @query.scan(/(?:(-)?(?:(is|tag|environment|assignee|component):)?(\S+))/) do |neg, key, value|
          list << Token.new(key: key, value: value, negated: !neg.nil?)
        end
        list
      end
    end

    private

    def apply_token(scope, token)
      case token.key
      when "is"
        case token.value
        when "resolved"
          token.negated ? scope.where.not(status: "resolved") : scope.where(status: "resolved")
        when "ignored"
          token.negated ? scope.where.not(status: "ignored") : scope.where(status: "ignored")
        when "unresolved"
          token.negated ? scope.where.not(status: "unresolved") : scope.where(status: "unresolved")
        when "assigned"
          token.negated ? scope.where(assignee_id: nil) : scope.where.not(assignee_id: nil)
        else
          scope
        end
      when "tag"
        # JSON array containment — portable enough for sqlite/pg json
        if token.negated
          scope.where.not("tags LIKE ?", "%\"#{sanitize_like(token.value)}\"%")
        else
          scope.where("tags LIKE ?", "%\"#{sanitize_like(token.value)}\"%")
        end
      when "environment"
        token.negated ? scope.where.not(environment: token.value) : scope.where(environment: token.value)
      when "component"
        token.negated ? scope.where.not(component: token.value) : scope.where(component: token.value)
      when "assignee"
        if token.value.match?(/\A\d+\z/)
          token.negated ? scope.where.not(assignee_id: token.value) : scope.where(assignee_id: token.value)
        else
          scope
        end
      else
        scope
      end
    end

    def sanitize_like(value)
      value.to_s.gsub(/[%_\\]/, "")
    end
  end
end
