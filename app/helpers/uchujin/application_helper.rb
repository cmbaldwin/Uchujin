# frozen_string_literal: true

module Uchujin
  module ApplicationHelper
    def status_badge(status)
      css = case status.to_s
      when "unresolved" then "badge badge-red"
      when "resolved" then "badge badge-green"
      when "ignored" then "badge badge-gray"
      when "up" then "badge badge-green"
      when "down" then "badge badge-red"
      else "badge badge-gray"
      end
      content_tag(:span, status.to_s, class: css)
    end

    def time_ago(time)
      return "—" if time.blank?
      "#{time_ago_in_words(time)} ago"
    end

    def truncate_message(msg, length = 120)
      msg.to_s.truncate(length)
    end
  end
end
