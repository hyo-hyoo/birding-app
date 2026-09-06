class ObservationVisualRenderer
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  PATTERN_FEATURES = %w[streaked barred spotted mottled iridescent].freeze
  ELEMENT_ATTRIBUTES = {
    "d" => :d,
    "cx" => :cx,
    "cy" => :cy,
    "r" => :r,
    "rx" => :rx,
    "ry" => :ry,
    "x1" => :x1,
    "x2" => :x2,
    "y1" => :y1,
    "y2" => :y2,
    "points" => :points,
    "fill" => :fill,
    "stroke_width" => :stroke_width
  }.freeze

  attr_reader :impression, :id_prefix, :label

  def initialize(impression, id_prefix:, label:)
    @impression = impression
    @id_prefix = sanitize_prefix(id_prefix)
    @label = label.to_s
  end

  def render
    raise KeyError, "outline has no stage 8 visual mapping" unless impression.mapped?

    tag.svg(
      safe_join([ definitions, scene, parts, details ]),
      class: "observation-impression-svg",
      viewBox: ObservationVisualCatalog.view_box,
      role: "img",
      aria: { label: },
      xmlns: "http://www.w3.org/2000/svg"
    )
  end

  private

  def outline
    @outline ||= ObservationVisualCatalog.outline!(impression.outline_key)
  end

  def definitions
    tag.defs do
      safe_join(pattern_definitions + gradient_definitions + clip_definitions)
    end
  end

  def pattern_definitions
    [
      tag.pattern(tag.path(d: "M3 -2 V12", stroke: ObservationVisualCatalog.outline_color, stroke_width: 2, opacity: 0.58),
        id: pattern_id("streaked"), width: 10, height: 10, patternUnits: "userSpaceOnUse", patternTransform: "rotate(-12)"),
      tag.pattern(tag.path(d: "M-2 5 H14", stroke: ObservationVisualCatalog.outline_color, stroke_width: 2, opacity: 0.58),
        id: pattern_id("barred"), width: 12, height: 12, patternUnits: "userSpaceOnUse", patternTransform: "rotate(-4)"),
      tag.pattern(tag.circle(cx: 5, cy: 5, r: 2.2, fill: ObservationVisualCatalog.outline_color, opacity: 0.58),
        id: pattern_id("spotted"), width: 12, height: 12, patternUnits: "userSpaceOnUse"),
      tag.pattern(safe_join([
        tag.circle(cx: 4, cy: 5, r: 2.8, fill: ObservationVisualCatalog.outline_color, opacity: 0.34),
        tag.circle(cx: 13, cy: 12, r: 3.6, fill: ObservationVisualCatalog.detail_color, opacity: 0.28)
      ]), id: pattern_id("mottled"), width: 18, height: 18, patternUnits: "userSpaceOnUse")
    ]
  end

  def gradient_definitions
    [
      tag.linearGradient(
        safe_join([
          tag.stop(offset: "0%", stop_color: "#3F719B", stop_opacity: 0.62),
          tag.stop(offset: "48%", stop_color: "#7F9660", stop_opacity: 0.48),
          tag.stop(offset: "100%", stop_color: "#A6537C", stop_opacity: 0.6)
        ]),
        id: pattern_id("iridescent"), x1: "0%", y1: "0%", x2: "100%", y2: "100%"
      )
    ]
  end

  def clip_definitions
    ObservationOptions.part_keys.map do |part_key|
      part = impression.part(part_key)
      tag.clipPath(safe_join(base_elements_for(part_key, part).map { |element| element_tag(element, {}) }), id: clip_id(part_key))
    end
  end

  def scene
    safe_join(outline.fetch(:scene).map { |element| painted_element(element, nil) })
  end

  def parts
    safe_join(ObservationOptions.part_keys.map { |part_key| render_part(part_key) })
  end

  def render_part(part_key)
    part = impression.part(part_key)
    base_color = ObservationVisualCatalog.color_hex(part.primary_color_key) || ObservationVisualCatalog.neutral_color
    secondary_color = ObservationVisualCatalog.color_hex(part.secondary_color_key)
    mapping = outline.fetch(:parts).fetch(part_key.to_sym)

    layers = base_elements_for(part_key, part).map do |element|
      element_tag(element, fill: base_color, class: "observation-impression__part", data: { part_key: })
    end

    if secondary_color
      layers.concat(mapping.fetch(:secondary).map do |element|
        element_tag(element, fill: secondary_color, class: "observation-impression__secondary", data: { part_key: })
      end)
    end

    layers.concat(feature_layers(part_key, part, mapping, secondary_color || contrast_color(base_color)))
    tag.g(safe_join(layers), data: { impression_part: part_key })
  end

  def base_elements_for(part_key, part)
    mapping = outline.fetch(:parts).fetch(part_key.to_sym)
    variant = mapping.fetch(:variants, {})[part.feature_key&.to_sym]
    return mapping.fetch(:base) unless variant
    return variant.fetch(:elements) if variant.fetch(:mode) == "replace"

    mapping.fetch(:base) + variant.fetch(:elements)
  end

  def feature_layers(part_key, part, mapping, accent_color)
    return [] unless part.feature_key

    layers = []
    if PATTERN_FEATURES.include?(part.feature_key)
      fill = "url(##{pattern_id(part.feature_key)})"
      layers << tag.rect(
        x: 0,
        y: 0,
        width: 320,
        height: 220,
        fill:,
        "clip-path" => "url(##{clip_id(part_key)})",
        class: "observation-impression__pattern",
        data: { feature_key: part.feature_key }
      )
    end

    mapping.fetch(:features, {}).fetch(part.feature_key.to_sym, []).each do |element|
      layers << painted_element(element, accent_color, data: { feature_key: part.feature_key })
    end
    layers
  end

  def details
    safe_join(outline.fetch(:details).map { |element| painted_element(element, nil) })
  end

  def painted_element(element, accent_color, data: nil)
    paint = element[:paint]
    attributes = case paint
    when "scene"
      { fill: "none", stroke: "#71887E", stroke_width: 3, stroke_linecap: "round" }
    when "scene_light"
      { fill: "none", stroke: "#A6B5AE", stroke_width: 2, stroke_linecap: "round", opacity: 0.72 }
    when "beak"
      { fill: "#C6A65A", stroke: ObservationVisualCatalog.outline_color, stroke_width: 2 }
    when "eye"
      { fill: ObservationVisualCatalog.outline_color }
    when "accent"
      { fill: accent_color, stroke: ObservationVisualCatalog.outline_color, stroke_width: 1.5, stroke_linejoin: "round" }
    when "accent_stroke"
      { fill: "none", stroke: accent_color, stroke_width: 2.5 }
    when "light"
      { fill: "none", stroke: "#F5F3EA", stroke_width: 3 }
    else
      {}
    end

    element_tag(element, attributes.merge(data:))
  end

  def element_tag(element, extra_attributes)
    attributes = element.fetch(:attrs).each_with_object({}) do |(key, value), result|
      result[ELEMENT_ATTRIBUTES.fetch(key.to_s)] = value
    end.merge(extra_attributes.compact)

    attributes[:stroke] ||= ObservationVisualCatalog.outline_color if attributes[:fill] && attributes[:fill] != "none"
    attributes[:stroke_width] ||= 2 if attributes[:stroke]
    attributes[:stroke_linejoin] ||= "round" if attributes[:stroke]

    case element.fetch(:element)
    when "path" then tag.path(**attributes)
    when "circle" then tag.circle(**attributes)
    when "ellipse" then tag.ellipse(**attributes)
    when "line" then tag.line(**attributes)
    when "polyline" then tag.polyline(**attributes)
    when "polygon" then tag.polygon(**attributes)
    end
  end

  def pattern_id(feature_key) = "#{id_prefix}-pattern-#{feature_key}"
  def clip_id(part_key) = "#{id_prefix}-clip-#{part_key}"

  def sanitize_prefix(value)
    prefix = value.to_s
    return prefix if /\A[a-zA-Z][a-zA-Z0-9_-]*\z/.match?(prefix)

    "impression-#{SecureRandom.hex(6)}"
  end

  def contrast_color(color)
    color.casecmp("#252729").zero? ? "#F5F3EA" : ObservationVisualCatalog.outline_color
  end
end
