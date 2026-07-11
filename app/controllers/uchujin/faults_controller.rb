# frozen_string_literal: true

module Uchujin
  class FaultsController < ApplicationController
    before_action :set_fault, only: %i[show resolve ignore reopen update]

    def index
      scope = Fault.all
      scope = QueryParser.new(params[:q]).apply(scope) if params[:q].present?
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(environment: params[:environment]) if params[:environment].present?
      @faults = scope.recent.limit(100)
      @query = params[:q]
    end

    def show
      @occurrences = @fault.occurrences.newest.limit(50)
      @occurrence = if params[:occurrence_id]
                      @fault.occurrences.find_by(id: params[:occurrence_id]) || @occurrences.first
      else
                      @occurrences.first
      end
      @comments = @fault.comments.newest
      @comment = Comment.new
    end

    def resolve
      @fault.resolve!(user_id: uchujin_user_id)
      redirect_to fault_path(@fault), notice: "Fault resolved."
    end

    def ignore
      @fault.ignore!
      redirect_to fault_path(@fault), notice: "Fault ignored."
    end

    def reopen
      @fault.reopen!
      redirect_to fault_path(@fault), notice: "Fault reopened."
    end

    def update
      if params[:fault]&.key?(:assignee_id)
        @fault.assign!(params[:fault][:assignee_id].presence)
      end
      if params[:fault]&.key?(:tags)
        tags = params[:fault][:tags].to_s.split(",").map(&:strip)
        @fault.tag_list = tags
        @fault.save!
      end
      redirect_to fault_path(@fault), notice: "Fault updated."
    end

    private

    def set_fault
      @fault = Fault.find(params[:id])
    end
  end
end
