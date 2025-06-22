# Telegram Bot with AI on Ruby on Rails

## Features

- AI-powered chat using OpenAI
- Weather information for any city, with unit selection (Celsius, Fahrenheit, Kelvin)
- Telegram commands: `/start`, `/stop`, `/help`, `/weather`
- Friendly, helpful responses and error handling

## Usage

- Type your question to get an AI answer (e.g., `What is the capital of France?`)
- Use `/weather` to get current weather for a city (the bot will prompt for city and units)
- Use `/start` to begin, `/stop` to end, `/help` for instructions

## Configuration

1. Install _Ruby 3.3.5_
2. Clone this repository.

```bash
git clone https://github.com/oasis-dot/rails_telegram_ai
```

3. Go to directory of this repository and run `bundle install`
4. Configure API keys.
   1. Rename `example.env` to `.env`
   2. Change in this files API keys, AI models, and base URI's.
5. Run server with `bin/dev` command
6. Enjoy using it!

## Development

- To run tests: `bundle exec rspec`

## Internationalization

- All bot messages are managed in `config/locales/en.yml` for easy customization.

## Future plans

- Expected to add Web UI to choose OpenAI models, API keys and more!
