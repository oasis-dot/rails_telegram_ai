require "telegram/bot"

namespace :bot do
  desc "Starts the Telegram bot listener"

  task start: :environment do
    token = ENV["TELEGRAM_BOT_TOKEN"]

    abort "FATAL: TELEGRAM_BOT_TOKEN is not set" if token.nil?

    puts "Starting Telegram bot listener..."

    Telegram::Bot::Client.run(token) do |bot|
      bot.api.get_updates(offset: -1)

      bot.listen do |message|
        next unless message.is_a?(Telegram::Bot::Types::Message)

        TelegramMessageProcessorJob.perform_later(message.to_h)
      end
    end
  end
end
