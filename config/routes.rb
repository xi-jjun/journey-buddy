Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  get '/test_def', to: 'test_api#test_def'

  post '/send-post-data', to: 'test_api#send_post_data'
end
