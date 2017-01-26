Rails.application.routes.draw do
  get 'users/show'

  devise_for :users, :controllers => {
    :registrations => "registrations"
  }
  resources :users, only: [:show]
  #resources :villages, only: [:show]
  resources :villages, only: [:show, :new, :create,:update] do
    collection do
      get :search

    end
  end
  root  'static_pages#home'
  match '/help',    to: 'static_pages#help',    via: 'get'
  #match '/creat_village',    to: 'static_pages#creat_village',    via: 'get'
  #match '/search_village',    to: 'static_pages#search_village',    via: 'get'
  #match '/village',    to: 'static_pages#village',    via: 'get'
  # match '/help',    to: 'static_pages#help',    via: 'get'
  
  # Serve websocket cable requests in-process
  mount ActionCable.server => '/cable'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
