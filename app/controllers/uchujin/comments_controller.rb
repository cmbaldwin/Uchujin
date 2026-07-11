# frozen_string_literal: true

module Uchujin
  class CommentsController < ApplicationController
    def create
      fault = Fault.find(params[:fault_id])
      comment = fault.comments.build(comment_params)
      comment.author_id = uchujin_user_id
      comment.author_name = uchujin_user_name
      if comment.save
        redirect_to fault_path(fault), notice: "Comment added."
      else
        redirect_to fault_path(fault), alert: comment.errors.full_messages.to_sentence
      end
    end

    private

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
