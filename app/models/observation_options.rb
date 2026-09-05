module ObservationOptions
  CONFIG_PATH = Rails.root.join("config/observation_options.yml")

  class << self
    def config
      @config ||= begin
        values = YAML.safe_load_file(CONFIG_PATH, aliases: false).deep_symbolize_keys
        deep_freeze(values)
      end
    end

    def outline_groups = config.fetch(:outline_groups)
    def orders = config.fetch(:orders)
    def outlines = config.fetch(:outlines)
    def colors = config.fetch(:colors)
    def parts = config.fetch(:parts)
    def features = config.fetch(:features)
    def certainties = config.fetch(:certainties)
    def activity_locations = config.fetch(:activity_locations)

    def outline_keys = keys_for(outlines)
    def color_keys = keys_for(colors)
    def part_keys = keys_for(parts)
    def certainty_keys = keys_for(certainties)
    def activity_location_keys = keys_for(activity_locations)

    def valid_outline_key?(key) = outline_keys.include?(key.to_s)
    def valid_color_key?(key) = color_keys.include?(key.to_s)
    def valid_part_key?(key) = part_keys.include?(key.to_s)
    def valid_certainty_key?(key) = certainty_keys.include?(key.to_s)
    def valid_activity_location_key?(key) = activity_location_keys.include?(key.to_s)

    def features_for(part_key)
      part = part_key.to_s
      features.select { |feature| feature.fetch(:parts).include?(part) }
    end

    def valid_feature_for_part?(feature_key, part_key)
      features_for(part_key).any? { |feature| feature.fetch(:key) == feature_key.to_s }
    end

    def label(section, key, locale: I18n.locale)
      I18n.t!("observation_options.#{section}.#{key}", locale:)
    end

    private

    def keys_for(entries)
      entries.map { |entry| entry.fetch(:key) }
    end

    def deep_freeze(value)
      case value
      when Hash
        value.each { |key, item| deep_freeze(key); deep_freeze(item) }
      when Array
        value.each { |item| deep_freeze(item) }
      end

      value.freeze
    end
  end
end
