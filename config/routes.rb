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

        controller 'buddy_setting' do
          post '/buddy', to: 'buddy_setting#init_user_buddy_settings'
        end

        # controller 'personality' do
        #   get '/buddy-role', to: 'personality#chat_role_list'
        #   post '/buddy-role', to: 'personality#chat_role_setting'
        # end
      end

      namespace :journeys do
        controller 'journey' do
          get '/check-traveling', to: 'journey#check_traveling'
          get '/:journey_id', to: 'journey#journey_detail'
          post '/', to: 'journey#start_journey'
          patch '/:journey_id/status', to: 'journey#journey_status_update'
        end
      end

      namespace :users do
        controller 'user' do
          post '/', to: 'user#sign_up'
          get '/:user_id', to: 'user#details'
          patch '/:user_id', to: 'user#update_info'
        end

        controller 'login' do
          post '/login', to: 'login#user_login'

          get '/kakao/login', to: 'login#kakao_login_url'
          get '/kakao/login/callback', to: 'login#kakao_login_callback'
        end

        controller 'personality' do
          get '/:user_id/personalities', to: 'personality#get_user_personalities'
          post '/personalities', to: 'personality#create_user_personality_settings'
        end
      end

      namespace :quests do
        controller 'quest' do
          get '/missions', to: 'quest#user_missions'
          post '/mission', to: 'quest#generate_random_mission'
          post '/missioin/complete', to: 'quest#complete_mission'
          patch '/missioin/reject', to: 'quest#reject_mission'
        end
      end
    end
  end

  # test api list (제거 예정)
  get '/test_def', to: 'test_api#test_def'

  post '/send-post-data', to: 'test_api#send_post_data'
end
