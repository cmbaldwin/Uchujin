# frozen_string_literal: true

module Uchujin
  module Context
    module_function

    def store
      if defined?(RequestStore)
        RequestStore.store[:uchujin_context] ||= {}
      else
        Thread.current[:uchujin_context] ||= {}
      end
    end

    def clear!
      if defined?(RequestStore)
        RequestStore.store[:uchujin_context] = {}
      else
        Thread.current[:uchujin_context] = {}
      end
    end

    def set(hash)
      store.merge!(hash.stringify_keys)
    end

    def capture
      store.dup
    end
  end
end
