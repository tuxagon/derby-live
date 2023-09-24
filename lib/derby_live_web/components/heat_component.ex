defmodule DerbyLiveWeb.HeatComponent do
  use Phoenix.Component

  import DerbyLiveWeb.SvgComponents

  embed_templates "heat_templates/*"

  attr :heat, DerbyLive.Racing.Heat, required: true

  def single_heat(assigns)
end
