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
    "x" => "x",
    "y" => "y",
    "width" => "width",
    "height" => "height",
    "x1" => "x1",
    "x2" => "x2",
    "y1" => "y1",
    "y2" => "y2",
    "points" => "points",
    "fill" => "fill",
    "stroke_width" => "stroke-width",
    "transform" => "transform"
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
      tag.clipPath(safe_join(base_elements_for(part_key).map { |element| element_tag(element, {}) }), id: clip_id(part_key))
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

    layers = base_elements_for(part_key).map do |element|
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
      secondary = secondary_elements(part_key, part, mapping).map do |element|
        painted_element(element, secondary_color, data: { secondary_for: part_key })
      end
      layers << tag.g(
        safe_join(secondary),
        class: "observation-impression__secondary",
        data: { part_key: },
        "clip-path" => "url(##{clip_id(part_key)})"
      )
    end

    tag.g(safe_join(layers), data: { impression_part: part_key })
  end

  def base_elements_for(part_key)
    outline.fetch(:parts).fetch(part_key.to_sym).fetch(:base)
  end

  def secondary_elements(part_key, part, mapping)
    return mapping.fetch(:secondary) unless ObservationVisualCatalog.visual_feature?(part_key, part.feature_key)

    mapping.fetch(:features, {})[part.feature_key.to_sym].presence || generated_feature_elements(part.feature_key, mapping.fetch(:feature_anchor))
  end

  def generated_feature_elements(feature_key, anchor)
    x = anchor.fetch(:x).to_f
    y = anchor.fetch(:y).to_f
    width = anchor.fetch(:width).to_f
    height = anchor.fetch(:height).to_f
    angle = anchor.fetch(:angle).to_f
    rotation = "rotate(#{format_number(angle)} #{format_number(x)} #{format_number(y)})"

    case feature_key.to_s
    when "eye_ring"
      [ generated_element("ellipse", "accent_stroke", cx: x, cy: y, rx: width * 0.16, ry: height * 0.24, fill: "none", stroke_width: 3) ]
    when "eye_stripe"
      [ generated_element("path", "accent", d: horizontal_curve(x, y, width * 0.72), fill: "none", stroke_width: [ height * 0.24, 4 ].max) ]
    when "eyebrow_stripe"
      [ generated_element("path", "accent", d: horizontal_curve(x, y - (height * 0.22), width * 0.68), fill: "none", stroke_width: [ height * 0.2, 3.5 ].max) ]
    when "cheek_patch"
      [ generated_element("ellipse", "accent", cx: x, cy: y + (height * 0.18), rx: width * 0.27, ry: height * 0.3, transform: rotation) ]
    when "throat_patch"
      [ generated_element("ellipse", "accent", cx: x - (width * 0.24), cy: y + (height * 0.52), rx: width * 0.25, ry: height * 0.34, transform: rotation) ]
    when "neck_ring"
      [ generated_element("path", "accent", d: horizontal_curve(x - (width * 0.28), y + (height * 0.56), width * 0.58), fill: "none", stroke_width: [ height * 0.26, 4 ].max) ]
    when "breast_band"
      [ generated_element("path", "accent", d: horizontal_curve(x, y, width * 0.86), fill: "none", stroke_width: [ height * 0.35, 7 ].max) ]
    when "wing_bars"
      [ generated_element("path", "accent", d: horizontal_curve(x, y, width * 0.84), fill: "none", stroke_width: [ height * 0.34, 8 ].max) ]
    when "wing_patch"
      [ generated_element("ellipse", "accent", cx: x, cy: y, rx: width * 0.34, ry: height * 0.34, transform: rotation) ]
    when "speculum"
      [ generated_element("ellipse", "accent", cx: x, cy: y, rx: width * 0.43, ry: height * 0.2, transform: rotation) ]
    when "tail_band"
      [ generated_element("path", "accent", d: horizontal_curve(x, y, width * 0.8), fill: "none", stroke_width: [ height * 0.38, 6 ].max) ]
    when "pale_tail_tip"
      [ generated_element("ellipse", "accent", cx: x + (width * 0.32), cy: y, rx: width * 0.28, ry: height * 0.42, transform: rotation) ]
    when "white_outer_tail"
      [ generated_element("ellipse", "accent", cx: x, cy: y, rx: width * 0.45, ry: height * 0.2, transform: rotation) ]
    else
      []
    end
  end

  def generated_element(element, paint, **attributes)
    {
      element:,
      paint:,
      attrs: attributes.transform_values { |value| value.is_a?(Numeric) ? format_number(value) : value }
    }
  end

  def horizontal_curve(x, y, width)
    half = width / 2
    "M#{format_number(x - half)} #{format_number(y)} Q#{format_number(x)} #{format_number(y + (width * 0.08))} #{format_number(x + half)} #{format_number(y)}"
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
    when "rect" then tag.rect(**attributes)
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
end
