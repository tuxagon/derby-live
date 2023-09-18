defmodule DerbyLiveWeb.EventLive.Index do
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Racing
  alias DerbyLive.Racing.Event

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    {:ok, stream(socket, :events, Racing.list_my_events(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, Racing.get_event!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Event{})
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
    event = Racing.get_event!(id)
    {:ok, _} = Racing.delete_event(event)

    {:noreply, stream_delete(socket, :events, event)}
  end

  def handle_event("archive", %{"id" => id}, socket) do
    event = Racing.get_event!(id)
    {:ok, event} = Racing.archive_event(event)

    {:noreply,
     socket
     |> put_flash(:info, "Event archived successfully")
     |> stream_insert(:events, event)}
  end
end
