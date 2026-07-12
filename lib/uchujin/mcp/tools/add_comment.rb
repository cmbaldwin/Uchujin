# frozen_string_literal: true

module Uchujin
  module Mcp
    module Tools
      class AddComment < Tool
        tool_name "add_comment"
        description "Add a triage comment to a fault (investigation notes, fix PR link, etc.)."
        input_schema(
          type: "object",
          properties: {
            fault_id: { type: "integer" },
            body: { type: "string", description: "Comment markdown/text" },
            author_name: { type: "string", description: "Display name (default: mcp-agent)" },
            author_id: { type: "integer", description: "Optional host user id" }
          },
          required: [ "fault_id", "body" ],
          additionalProperties: false
        )

        def self.call(fault_id:, body:, author_name: "mcp-agent", author_id: nil, **_)
          fault = Fault.find(fault_id)
          comment = fault.comments.create!(
            body: body.to_s,
            author_name: author_name.presence || "mcp-agent",
            author_id: author_id
          )
          { ok: true, comment: Serializers.comment(comment) }
        rescue ActiveRecord::RecordNotFound
          { error: "fault not found", fault_id: fault_id }
        rescue ActiveRecord::RecordInvalid => e
          { error: e.message }
        end
      end
    end
  end
end
