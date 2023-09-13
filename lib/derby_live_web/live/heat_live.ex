defmodule DerbyLiveWeb.HeatLive do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing

  def mount(_params, _session, socket) do
    heats = Racing.list_heats()
    {:ok, assign(socket, :heats, heats)}
  end

  def render(assigns) do
    ~L"""
    <div class="container">
      <div class="row">
        <div class="col">
          <h1>Heats</h1>
          <ul>
            <%= for {heat_number, lanes} <- @heats do %>
              <li>
                <h2>Heat <%= heat_number %></h2>
                <ul>
                  <%= for {racer, racer_heat} <- lanes do %>
                    <li>
                      <%= racer_heat.lane_number %>: (<%= racer_heat.finish_place %>) <%= racer.car_number %> - <%= racer.first_name %> <%= racer.last_name %>
                    </li>
                  <% end %>
                </ul>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
