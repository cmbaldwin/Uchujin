# frozen_string_literal: true

module Uchujin
  module Mcp
    # Base class for MCP tools. Subclasses define name, description, input_schema, call.
    class Tool
      class << self
        def tool_name(value = nil)
          @tool_name = value if value
          @tool_name || name.demodulize.underscore
        end

        def description(value = nil)
          @description = value if value
          @description || ""
        end

        def input_schema(value = nil)
          @input_schema = value if value
          @input_schema || { type: "object", properties: {}, additionalProperties: false }
        end

        def annotations(value = nil)
          @annotations = value if value
          @annotations || {}
        end

        def definition
          {
            name: tool_name,
            description: description,
            inputSchema: input_schema
          }.tap do |h|
            h[:annotations] = annotations if annotations.present?
          end
        end

        # Subclasses implement: call(**args) -> Hash
        def call(**)
          raise NotImplementedError
        end
      end
    end
  end
end
