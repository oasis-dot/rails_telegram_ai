class OpenWeatherProcessorJob < ApplicationJob
  queue_as :default

  def perform(city:, units: "standard")
    client = OpenWeather::Client.new(api_key: ENV["OPEN_WEATHER_API_KEY"])
    data = client.current_weather(city: city, units: units)

    format_weather_data(data)
  end

  private

  def format_weather_data(data)
    return I18n.t("weather.not_available") if data.nil? || data.empty?

    city = data.name
    temperature = data.main.temp
    feels_like = data.main.feels_like
    description = data.weather.first.description
    temperature_unit =
      case data.units
      when :metric
        "°C"
      when :imperial
        "°F"
      else
        "K"
      end

    if city.present? && temperature.present? && description.present? && feels_like.present?
      [
        I18n.t("weather.current", city: city),
        I18n.t("weather.temperature", temperature: temperature, unit: temperature_unit),
        I18n.t("weather.feels_like", feels_like: feals_like, unit: temperature_unit),
        I18n.t("weather.description", description: description.capitalize)
      ].join("\n")
    else
      I18n.t("weather.could_not_retrieve")
    end
  end
end
