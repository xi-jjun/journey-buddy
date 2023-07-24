Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      namespace :chats do
        controller 'chatting' do
          get '/', to: 'chatting#get_all_chats'
          post '/', to: 'chatting#send_chat'
        end
      end
    end
  end

  # test api list (제거 예정)
  get '/test_def', to: 'test_api#test_def'

  post '/send-post-data', to: 'test_api#send_post_data'
end
