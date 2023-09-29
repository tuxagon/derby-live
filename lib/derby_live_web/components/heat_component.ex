defmodule DerbyLiveWeb.HeatComponent do
  use Phoenix.Component

  import DerbyLiveWeb.SvgComponents

  embed_templates "heat_templates/*"

  attr :heat, DerbyLive.Racing.Heat, required: true

  def heat(assigns)

  attr :heat, DerbyLive.Racing.Heat, required: true

  def single_heat(assigns)

  attr :heat_number, :integer, required: true
  attr :heat_location, :atom, required: true
  attr :class, :string, default: nil

  def heat_select_button(assigns) do
    assigns =
      assign(
        assigns,
        :heat_select_button_color_class,
        case assigns.heat_location do
          :current -> "bg-green-500 hover:bg-green-400"
          :next -> "bg-yellow-500 hover:bg-yellow-400"
          :upcoming -> "bg-red-500 hover:bg-red-400"
          :finished -> "bg-gray-500 hover:bg-gray-400"
        end
      )

    ~H"""
    <button
      phx-click="select_heat"
      phx-value-heat-number={@heat_number}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @heat_select_button_color_class,
        @class
      ]}
    >
      <%= String.pad_leading(@heat_number |> to_string, 2, "0") %>
    </button>
    """
  end

  defp human_time(time) do
    Timex.from_now(time)
  end

  defp place_ordinal(1), do: "1st"
  defp place_ordinal(2), do: "2nd"
  defp place_ordinal(3), do: "3rd"
  defp place_ordinal(place), do: "#{place}th"
end
