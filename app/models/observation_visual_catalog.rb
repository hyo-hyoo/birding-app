module ObservationVisualCatalog
  CONFIG_PATH = Rails.root.join("config/observation_visuals.yml")
  OUTLINE_KEYS = ObservationOptions.outline_keys.freeze
  ELEMENTS = %w[path circle ellipse line polyline polygon rect].freeze
  ATTRIBUTES = %w[d cx cy r rx ry x y width height x1 x2 y1 y2 points fill stroke_width transform].freeze
  PAINTS = %w[scene scene_light beak eye accent accent_stroke light].freeze
  FEATURE_ANCHOR_KEYS = %i[x y width height angle].freeze
  VISUAL_FEATURE_KEYS = {
    "head" => %w[eye_ring eye_stripe eyebrow_stripe cheek_patch throat_patch neck_ring],
    "chest_belly" => %w[breast_band],
    "wing" => %w[wing_bars wing_patch speculum],
    "tail" => %w[tail_band pale_tail_tip white_outer_tail]
  }.freeze
  HEX_COLOR = /\A#[0-9A-F]{6}\z/i
  VIEW_BOX = /\A-?\d+(?:\.\d+)?(?: +-?\d+(?:\.\d+)?){3}\z/
  SOURCE_FRAME_KEYS = %i[x y width height].freeze
  SOURCE_TRANSFORM = /\Atranslate\(-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?\) scale\(-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?\)\z/

  class InvalidConfiguration < StandardError; end

  class << self
    def config
      @config ||= load_config
    end

    def outlines = config.fetch(:outlines)
    def outline_keys = outlines.keys.map(&:to_s)
    def view_box = config.fetch(:view_box)
    def neutral_color = config.fetch(:neutral_color)
    def outline_color = config.fetch(:outline_color)
    def detail_color = config.fetch(:detail_color)

    def mapped?(outline_key)
      outlines.key?(outline_key.to_s.to_sym)
    end

    def outline!(outline_key)
      outlines.fetch(outline_key.to_s.to_sym)
    end

    def color_hex(color_key)
      ObservationOptions.colors.find { |color| color.fetch(:key) == color_key.to_s }&.fetch(:hex)
    end

    def visual_feature?(part_key, feature_key)
      VISUAL_FEATURE_KEYS.fetch(part_key.to_s, []).include?(feature_key.to_s)
    end

    def source_geometry(outline_key)
      @source_geometries ||= {}
      @source_geometries[outline_key.to_s] ||= load_source_geometry(outline!(outline_key)).freeze
    end

    private

    def load_config
      values = YAML.safe_load_file(CONFIG_PATH, aliases: false).deep_symbolize_keys
      validate!(values)
      deep_freeze(values)
    end

    def validate!(values)
      invalid!("version must be 1") unless values[:version] == 1
      invalid!("view_box must contain four numbers") unless VIEW_BOX.match?(values[:view_box].to_s)

      %i[neutral_color outline_color detail_color].each do |key|
        invalid!("#{key} must be a hex color") unless HEX_COLOR.match?(values[key].to_s)
      end

      outlines = values.fetch(:outlines)
      invalid!("stage 8 outline keys are incomplete") unless outlines.keys.map(&:to_s).sort == OUTLINE_KEYS.sort

      outlines.each do |outline_key, outline|
        validate_outline!(outline_key.to_s, outline)
      end
    rescue KeyError => error
      invalid!("missing #{error.key}")
    end

    def validate_outline!(outline_key, outline)
      invalid!("unknown outline #{outline_key}") unless ObservationOptions.valid_outline_key?(outline_key)

      expected_asset = ObservationOptions.outlines.find { |entry| entry.fetch(:key) == outline_key }.fetch(:asset)
      invalid!("source asset mismatch for #{outline_key}") unless outline.fetch(:source_asset) == expected_asset

      validate_source_frame!(outline_key, outline.fetch(:source_frame))

      validate_elements!(outline.fetch(:scene), "#{outline_key}.scene")
      validate_elements!(outline.fetch(:details), "#{outline_key}.details")

      parts = outline.fetch(:parts)
      invalid!("#{outline_key} must map all four parts") unless parts.keys.map(&:to_s).sort == ObservationOptions.part_keys.sort

      parts.each do |part_key, part|
        path = "#{outline_key}.#{part_key}"
        invalid!("#{path} base must not be empty") if part.fetch(:base).empty?
        invalid!("#{path} secondary must not be empty") if part.fetch(:secondary).empty?
        validate_elements!(part.fetch(:base), "#{path}.base")
        validate_elements!(part.fetch(:secondary), "#{path}.secondary")
        validate_feature_anchor!(part.fetch(:feature_anchor), path)

        part.fetch(:features, {}).each do |feature_key, elements|
          validate_feature!(feature_key, part_key, path)
          validate_elements!(elements, "#{path}.features.#{feature_key}")
        end
      end
    end

    def validate_feature_anchor!(anchor, path)
      invalid!("#{path}.feature_anchor must have x, y, width, height, and angle") unless anchor.keys.sort == FEATURE_ANCHOR_KEYS.sort
      invalid!("#{path}.feature_anchor values must be numeric") unless anchor.values.all? { |value| value.is_a?(Numeric) }
      invalid!("#{path}.feature_anchor dimensions must be positive") unless anchor[:width].to_f.positive? && anchor[:height].to_f.positive?
    end

    def validate_source_frame!(outline_key, frame)
      invalid!("#{outline_key}.source_frame must have x, y, width, and height") unless frame.keys.sort == SOURCE_FRAME_KEYS.sort
      invalid!("#{outline_key}.source_frame dimensions must be positive") unless frame[:width].to_f.positive? && frame[:height].to_f.positive?
      invalid!("#{outline_key}.source_frame values must be numeric") unless frame.values.all? { |value| value.is_a?(Numeric) }
    end

    def load_source_geometry(outline)
      source_path = Rails.root.join("app/assets/images", outline.fetch(:source_asset))
      document = Nokogiri::XML(source_path.read) { |config| config.strict.nonet }
      svg = document.at_xpath("/*[local-name()='svg']")
      group = svg&.at_xpath("./*[local-name()='g']")
      view_box = svg&.[]("viewBox").to_s.split.map(&:to_f)
      transform = group&.[]("transform").to_s
      paths = group&.xpath(".//*[local-name()='path']")&.map { |path| path["d"].to_s }

      invalid!("source asset must have a positive viewBox") unless view_box.length == 4 && view_box.drop(2).all?(&:positive?)
      invalid!("source asset transform is unsupported") unless SOURCE_TRANSFORM.match?(transform)
      invalid!("source asset must contain paths") if paths.blank? || paths.any? { |path| path.blank? || path.match?(/[<>]|javascript:|https?:/i) }

      { view_box:, transform:, paths: paths.freeze }.freeze
    rescue Errno::ENOENT, Nokogiri::XML::SyntaxError => error
      invalid!("invalid source asset: #{error.message}")
    end

    def validate_feature!(feature_key, part_key, path)
      return if ObservationOptions.valid_feature_for_part?(feature_key, part_key)

      invalid!("feature #{feature_key} does not apply to #{path}")
    end

    def validate_elements!(elements, path)
      invalid!("#{path} must be an array") unless elements.is_a?(Array)

      elements.each_with_index do |element, index|
        item_path = "#{path}[#{index}]"
        invalid!("unsupported element at #{item_path}") unless ELEMENTS.include?(element.fetch(:element))
        invalid!("unsupported paint at #{item_path}") if element[:paint] && !PAINTS.include?(element[:paint])

        attributes = element.fetch(:attrs)
        unknown_attributes = attributes.keys.map(&:to_s) - ATTRIBUTES
        invalid!("unsupported attributes at #{item_path}: #{unknown_attributes.join(', ')}") if unknown_attributes.any?

        attributes.each_value do |value|
          unsafe = value.to_s.match?(/<|>|javascript:|https?:|url\s*\(/i)
          invalid!("unsafe value at #{item_path}") if unsafe
        end
      end
    rescue KeyError => error
      invalid!("missing #{error.key} at #{path}")
    end

    def invalid!(message)
      raise InvalidConfiguration, message
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
