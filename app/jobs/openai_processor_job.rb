class OpenaiProcessorJob < ApplicationJob
  URI_BASE = ENV["OPENAI_API_BASE"]
  ACCESS_TOKEN = ENV["OPENAI_API_KEY"]
  MODEL = ENV["OPENAI_MODEL"]
  ROLE = ENV["OPENAI_ROLE"]
  CONTENT_BEFORE = I18n.t("openai_processor.content_before")

  queue_as :default

  def perform(message_data:)
    call_openai_api(message_data)
  end

  private

  def call_openai_api(message_data)
    message_data = format(CONTENT_BEFORE, message_data: message_data)

    client = OpenAI::Client.new(
      access_token: ACCESS_TOKEN,
      uri_base: URI_BASE
    )

    response = client.chat(
      parameters: {
        model: MODEL,
        messages: [ { role: ROLE, content: message_data } ],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
