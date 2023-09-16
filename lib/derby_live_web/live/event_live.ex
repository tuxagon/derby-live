defmodule DerbyLiveWeb.EventLive do
  use DerbyLiveWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="container">
      <h1>Events</h1>
    </div>
    """
  end
end
