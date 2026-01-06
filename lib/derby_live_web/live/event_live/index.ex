defmodule DerbyLiveWeb.EventLive.Index do
  use DerbyLiveWeb, :live_view

  require Ash.Query

  alias DerbyLive.Racing.Event
  alias DerbyLive.Racing.Racer
  alias DerbyLive.Racing.RacerHeat

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    events = list_events_for_user(user.id)
    {:ok, stream(socket, :events, events)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    event = get_event!(id)

    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, event)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({DerbyLiveWeb.EventLive.FormComponent, {:saved, event}}, socket) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  def handle_info({DerbyLiveWeb.EventLive.Index, {:saved, event}}, socket) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = get_event!(id)
    :ok = Ash.destroy!(event)

    {:noreply, stream_delete(socket, :events, event)}
  end

  def handle_event("archive", %{"id" => id}, socket) do
    event = get_event!(id)
    {:ok, event} = Ash.update(event, action: :archive)

    {:noreply,
     socket
     |> put_flash(:info, "Event archived successfully")
     |> stream_insert(:events, event)}
  end

  def handle_event("reset", %{"id" => id}, socket) do
    event = get_event!(id)
    event_id = event.id

    # Delete all racer_heats and racers for this event
    RacerHeat
    |> Ash.Query.filter(event_id == ^event_id)
    |> Ash.bulk_destroy!(:destroy, %{})

    Racer
    |> Ash.Query.filter(event_id == ^event_id)
    |> Ash.bulk_destroy!(:destroy, %{})

    {:noreply,
     socket
     |> put_flash(:info, "Event reset successfully")
     |> stream_insert(:events, event)}
  end

  # Helper functions using Ash

  defp list_events_for_user(user_id) do
    Event
    |> Ash.Query.for_read(:for_user, %{user_id: user_id})
    |> Ash.read!()
  end

  defp get_event!(id) do
    Ash.get!(Event, id)
  end
end
