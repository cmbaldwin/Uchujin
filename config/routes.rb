# frozen_string_literal: true

Uchujin::Engine.routes.draw do
  root to: "dashboard#show"

  resources :faults, only: %i[index show update] do
    member do
      post :resolve
      post :ignore
      post :reopen
    end
    resources :comments, only: %i[create]
  end

  resources :deployments, only: %i[index show]
  resources :uptime_checks, only: %i[index]
  resources :check_ins, only: %i[index create]

  namespace :api do
    resources :deployments, only: %i[create]
    post "check_ins/:name/ping", to: "check_ins#ping", as: :check_in_ping
  end
end
