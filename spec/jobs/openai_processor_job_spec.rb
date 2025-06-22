require "rails_helper"

RSpec.describe OpenaiProcessorJob, type: :job do
  describe "#perform" do
    let(:message_data) { "What is the capital of France?" }
    let(:formatted_message) { I18n.t("openai_processor.content_before", message_data: message_data) }
    let(:response_content) { "The capital of France is Paris." }

    subject(:job) { OpenaiProcessorJob.new }

    before do
      allow(OpenAI::Client).to receive(:new).and_return(double(chat: { "choices" => [ { "message" => { "content" => response_content } } ] }))
    end

    it "calls the OpenAI API with the formatted message data" do
      expect(job).to receive(:call_openai_api).with(message_data)

      job.perform(message_data: message_data)
    end

    it "returns the response content from OpenAI API" do
      expect(job.perform(message_data: message_data)).to eq(response_content)
    end
  end
end
