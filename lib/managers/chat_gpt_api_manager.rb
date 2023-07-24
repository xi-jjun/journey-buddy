require 'openai'

class ChatGptApiManager
  CHAT_GPT_API_KEY = ENV['CHAT_GPT_API_KEY']

  module Role
    ASSISTANT = 'assistant' # Chat GPT
    USER = 'user' # 사용자
    SYSTEM = 'system' # 역할 설정
  end

  class << self
    # @param [Hashes] chat_context ex) [ { wrtier: "user", content: "Hello!" }, ... ]
    # @return [String] Chat GPT answer
    def request_answer_to_chat_gpt(chat_context)
      chat_gpt_client = OpenAI::Client.new(access_token: CHAT_GPT_API_KEY)
      response = chat_gpt_client.chat(
        parameters: {
          model: "gpt-3.5-turbo", # Required.
          messages: pre_processing(chat_context), # Required.
          temperature: 0.8,
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("Chat GPT API error #{e.message}")
      {}
    end

    private

    def pre_processing(chat_context)
      messages = []
      chat_context.each do |chat|
        chat_role = case chat[:writer]
                    when Chat::Writer::ASSISTANT
                      Role::ASSISTANT
                    when Chat::Writer::USER
                      Role::USER
                    when Chat::Writer::SYSTEM
                      Role::SYSTEM
                    else
                      next
                    end
        messages << { role: chat_role, content: chat[:content] }
      end

      messages
    end
  end
end
