defmodule DerbyLiveWeb.EventLive.FormComponent do
  use DerbyLiveWeb, :live_component

  alias DerbyLive.Racing.Event

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage event records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Event</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{event: event, current_user: current_user} = assigns, socket) do
    form =
      if event do
        AshPhoenix.Form.for_update(event, :update, as: "event")
      else
        AshPhoenix.Form.for_create(Event, :create,
          as: "event",
          prepare_source: fn changeset ->
            Ash.Changeset.set_argument(changeset, :user_id, current_user.id)
          end
        )
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(form))}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, event_params)
    {:noreply, assign(socket, :form, to_form(form))}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, flash_message(socket.assigns.action))
         |> push_patch(to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  defp flash_message(:edit), do: "Event updated successfully"
  defp flash_message(:new), do: "Event created successfully"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
