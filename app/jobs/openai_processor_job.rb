class OpenaiProcessorJob < ApplicationJob
  queue_as :default

  def perform(message_data)
    puts "Processing OpenAI request..."

    call_openai_api(message_data)
  end

  private

  def call_openai_api(message_data)
    message_data = message_data.gsub("/ask ", "").strip
    client = OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"],
      uri_base: "https://api.groq.com/openai"
    )

    response = client.chat(
      parameters: {
        model: "llama3-8b-8192", # Required.
        messages: [ { role: "user", content: message_data } ], # Required.
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
