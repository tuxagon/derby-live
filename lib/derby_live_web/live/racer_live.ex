defmodule DerbyLiveWeb.RacerLive do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing

  def mount(_params, _session, socket) do
    racers = Racing.list_racers()
    {:ok, assign(socket, :racers, racers)}
  end

  def render(assigns) do
    ~L"""
    <div class="container">
      <div class="row">
        <div class="col">
          <h1>Racers</h1>
          <ul>
            <%= for racer <- @racers do %>
              <li>
                <%= racer.car_number %> - <%= racer.first_name %> <%= racer.last_name %>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
