defmodule DerbyLiveWeb.SvgComponents do
  use Phoenix.Component

  embed_templates "svg_templates/*"

  attr :color, :string, required: true
  attr :scale, :float, default: 1.0
  attr :class, :string, default: ""
  def derby_car(assigns)
end
