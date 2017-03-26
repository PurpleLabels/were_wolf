Rails.application.routes.draw do
  get 'games/new'

  get 'votes/new'

  get 'users/show'

  devise_for :users, controllers: {
    registrations: 'registrations'
  }
  devise_scope :user do
    authenticated :user do
      root to: 'villages#search'
    end
    unauthenticated :user do
      root to: 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  resources :users, only: [:show]
  # resources :villages, only: [:show]
  resources :villages, only: [:show, :new, :create, :update] do
    collection do
      get :search, :reload
    end
    resources :games, only: [:new] do
      collection do
        get :night, :stop, :vote, :reload, :to_vote
      end
    end
  end



  match '/help', to: 'static_pages#help', via: 'get'
  # match '/creat_village',    to: 'static_pages#creat_village',    via: 'get'
  # match '/search_village',    to: 'static_pages#search_village',    via: 'get'
  # match '/village',    to: 'static_pages#village',    via: 'get'
  # match '/help',    to: 'static_pages#help',    via: 'get'

  # Serve websocket cable requests in-process
  mount ActionCable.server => '/cable'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
