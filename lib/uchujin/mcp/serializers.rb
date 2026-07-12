# frozen_string_literal: true

module Uchujin
  module Mcp
    module Serializers
      module_function

      def fault_summary(fault)
        {
          id: fault.id,
          class_name: fault.class_name,
          message: fault.message.to_s.truncate(500),
          status: fault.status,
          component: fault.component,
          environment: fault.environment,
          occurrences_count: fault.occurrences_count,
          first_seen_at: iso(fault.first_seen_at),
          last_seen_at: iso(fault.last_seen_at),
          resolved_at: iso(fault.resolved_at),
          assignee_id: fault.assignee_id,
          tags: fault.tag_list,
          revision: fault.revision,
          fingerprint: fault.fingerprint,
          count_24h: fault.windowed_count
        }
      end

      def fault_detail(fault, occurrence_limit: 10)
        latest = fault.occurrences.newest.limit(occurrence_limit)
        fault_summary(fault).merge(
          sample_context: fault.sample_context,
          comments_count: fault.comments.count,
          latest_occurrences: latest.map { |o| occurrence_summary(o) },
          comments: fault.comments.newest.limit(20).map { |c| comment(c) }
        )
      end

      def occurrence_summary(occ)
        {
          id: occ.id,
          fault_id: occ.fault_id,
          occurred_at: iso(occ.occurred_at),
          message: occ.message.to_s.truncate(500),
          component: occ.component,
          environment: occ.environment,
          revision: occ.revision,
          app_frames: Array(occ.backtrace_app).first(8),
          request: summarize_request(occ)
        }
      end

      def occurrence_detail(occ)
        occurrence_summary(occ).merge(
          backtrace: Array(occ.backtrace).first(80),
          backtrace_app: Array(occ.backtrace_app),
          source_context: Array(occ.source_context_lines).first(10),
          cause: occ.cause,
          context: occ.context,
          breadcrumbs: Array(occ.breadcrumbs).last(30),
          server_stats: occ.server_stats,
          params: occ.params,
          request_metadata: occ.request_metadata,
          client_info: occ.client_info
        )
      end

      def comment(c)
        {
          id: c.id,
          fault_id: c.fault_id,
          body: c.body,
          author_id: c.author_id,
          author_name: c.author_name,
          created_at: iso(c.created_at)
        }
      end

      def deployment(d)
        {
          id: d.id,
          sha: d.sha,
          short_sha: d.short_sha,
          environment: d.environment,
          deployed_at: iso(d.deployed_at),
          user: d.user,
          repository: d.repository
        }
      end

      def check_in(c)
        {
          id: c.id,
          name: c.name,
          expected_every_seconds: c.expected_every_seconds,
          last_seen_at: iso(c.last_seen_at),
          ping_count: c.ping_count,
          overdue: c.overdue?
        }
      end

      def uptime_check(u)
        {
          id: u.id,
          url: u.url,
          status: u.status,
          status_code: u.status_code,
          response_time_ms: u.response_time_ms,
          error_message: u.error_message,
          checked_at: iso(u.checked_at)
        }
      end

      def summarize_request(occ)
        meta = occ.request_metadata || {}
        client = occ.client_info || {}
        {
          method: meta["method"] || meta[:method],
          url: meta["url"] || meta[:url],
          controller: meta["controller"] || meta[:controller],
          action: meta["action"] || meta[:action],
          ip: client["ip"] || client[:ip]
        }.compact
      end

      def iso(time)
        time&.iso8601
      end
    end
  end
end
