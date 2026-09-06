class ObservationVisualRenderer
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  PART_DRAW_ORDER = %w[chest_belly tail wing head].freeze
  ELEMENT_ATTRIBUTES = {
    "d" => "d",
    "cx" => "cx",
    "cy" => "cy",
    "r" => "r",
    "rx" => "rx",
    "ry" => "ry",
    "x1" => "x1",
    "x2" => "x2",
    "y1" => "y1",
    "y2" => "y2",
    "points" => "points",
    "fill" => "fill",
    "stroke_width" => "stroke-width"
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
      safe_join([ definitions, scene, parts, silhouette_outline, details ]),
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
      safe_join(clip_definitions + [ silhouette_clip_definition ].compact)
    end
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
    content = safe_join(PART_DRAW_ORDER.map { |part_key| render_part(part_key) })
    return content unless source_frame

    tag.g(content, "clip-path" => "url(##{silhouette_clip_id})")
  end

  def render_part(part_key)
    part = impression.part(part_key)
    base_color = ObservationVisualCatalog.color_hex(part.primary_color_key) || ObservationVisualCatalog.neutral_color
    secondary_color = ObservationVisualCatalog.color_hex(part.secondary_color_key)
    mapping = outline.fetch(:parts).fetch(part_key.to_sym)

    layers = base_elements_for(part_key, part).map do |element|
      element_tag(
        element,
        fill: base_color,
        stroke: ObservationVisualCatalog.outline_color,
        stroke_width: 2,
        class: "observation-impression__part",
        data: { part_key: }
      )
    end

    if secondary_color
      layers.concat(mapping.fetch(:secondary).map do |element|
        element_tag(element, fill: secondary_color, stroke: "none", class: "observation-impression__secondary", data: { part_key: })
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
    mapping.fetch(:features, {}).fetch(part.feature_key.to_sym, []).each do |element|
      layers << painted_element(element, accent_color, data: { feature_key: part.feature_key })
    end
    layers
  end

  def silhouette_clip_definition
    return unless source_frame

    tag.clipPath(
      source_shape({ fill: "#000000", stroke: "none" }),
      id: silhouette_clip_id,
      clipPathUnits: "userSpaceOnUse"
    )
  end

  def silhouette_outline
    return "" unless source_frame

    source_shape(
      {
      fill: "none",
      stroke: ObservationVisualCatalog.outline_color,
      stroke_width: 2.5,
      stroke_linejoin: "round",
      vector_effect: "non-scaling-stroke"
      }
    )
  end

  def source_shape(path_attributes)
    geometry = ObservationVisualCatalog.source_geometry(impression.outline_key)
    _, _, source_width, source_height = geometry.fetch(:view_box)
    frame = source_frame
    scale = [ frame.fetch(:width).to_f / source_width, frame.fetch(:height).to_f / source_height ].min
    x = frame.fetch(:x).to_f + ((frame.fetch(:width).to_f - (source_width * scale)) / 2)
    y = frame.fetch(:y).to_f + ((frame.fetch(:height).to_f - (source_height * scale)) / 2)
    normalized_attributes = path_attributes.to_h { |key, value| [ key.to_s.tr("_", "-"), value ] }
    transform = [
      "translate(#{format_number(x)} #{format_number(y)})",
      "scale(#{format_number(scale)})",
      geometry.fetch(:transform)
    ].join(" ")
    safe_join(geometry.fetch(:paths).map do |path|
      tag.path(**normalized_attributes.merge("d" => path, "transform" => transform))
    end)
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
      if element.dig(:attrs, :fill).to_s == "none"
        { fill: "none", stroke: accent_color, stroke_width: 2.5, stroke_linejoin: "round" }
      else
        { fill: accent_color, stroke: "none" }
      end
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
    end
    extra_attributes.compact.each do |key, value|
      normalized_key = %i[class data].include?(key) ? key : key.to_s.tr("_", "-")
      attributes[normalized_key] = value
    end

    attributes["stroke-width"] ||= 2 if attributes["stroke"]
    attributes["stroke-linejoin"] ||= "round" if attributes["stroke"]

    case element.fetch(:element)
    when "path" then tag.path(**attributes)
    when "circle" then tag.circle(**attributes)
    when "ellipse" then tag.ellipse(**attributes)
    when "line" then tag.line(**attributes)
    when "polyline" then tag.polyline(**attributes)
    when "polygon" then tag.polygon(**attributes)
    end
  end

  def clip_id(part_key) = "#{id_prefix}-clip-#{part_key}"
  def silhouette_clip_id = "#{id_prefix}-clip-silhouette"
  def source_frame = outline[:source_frame]

  def format_number(value)
    format("%.6f", value).sub(/0+\z/, "").sub(/\.\z/, "")
  end

  def sanitize_prefix(value)
    prefix = value.to_s
    return prefix if /\A[a-zA-Z][a-zA-Z0-9_-]*\z/.match?(prefix)

    "impression-#{SecureRandom.hex(6)}"
  end

  def contrast_color(color)
    color.casecmp("#252729").zero? ? "#F5F3EA" : ObservationVisualCatalog.outline_color
  end
end
