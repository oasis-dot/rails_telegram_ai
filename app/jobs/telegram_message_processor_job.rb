require "telegram/bot"

class TelegramMessageProcessorJob < ApplicationJob
  queue_as :default

  def perform(message_data)
    chat_id = message_data[:chat][:id]
    text = message_data[:text]
    first_name = message_data[:from][:first_name]

    token = ENV["TELEGRAM_BOT_TOKEN"]
    bot_api = Telegram::Bot::Api.new(token)

    response_text = case text
    when "/start"
                      "Hello from a Sidekiq Job, #{first_name}!"
    when "/stop"
                      "Bye from a Sidekiq Job, #{first_name}!"
    else
                      "I received your message: '#{text}', but I'm just a simple job."
    end

    bot_api.send_message(chat_id: chat_id, text: response_text)
  end
end
