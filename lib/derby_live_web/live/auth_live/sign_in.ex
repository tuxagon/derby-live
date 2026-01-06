defmodule DerbyLiveWeb.AuthLive.SignIn do
  @moduledoc """
  Custom sign-in LiveView for magic link authentication.
  """
  use DerbyLiveWeb, :live_view

  alias DerbyLive.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign In")
     |> assign(:email, "")
     |> assign(:submitted, false)
     |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to Derby Live
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Enter your email and we'll send you a magic link to sign in.
          </p>
        </div>

        <%= if @submitted do %>
          <div class="rounded-md bg-green-50 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-green-800">
                  Check your email!
                </h3>
                <div class="mt-2 text-sm text-green-700">
                  <p>
                    If an account exists with that email, we've sent you a magic link to sign in.
                    Check your inbox and click the link to continue.
                  </p>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <.simple_form for={%{}} phx-submit="request_magic_link" class="mt-8 space-y-6">
            <%= if @error do %>
              <div class="rounded-md bg-red-50 p-4">
                <div class="text-sm text-red-700">{@error}</div>
              </div>
            <% end %>

            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <input
                  id="email"
                  name="email"
                  type="email"
                  autocomplete="email"
                  required
                  value={@email}
                  class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Send magic link
              </button>
            </div>
          </.simple_form>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("request_magic_link", %{"email" => email}, socket) do
    # Request magic link through AshAuthentication
    strategy = AshAuthentication.Info.strategy!(User, :magic_link)

    # The action can return :ok, {:ok, _}, or {:error, _}
    case AshAuthentication.Strategy.action(strategy, :request, %{"email" => email}) do
      :ok ->
        {:noreply, assign(socket, submitted: true, email: email)}

      {:ok, _} ->
        {:noreply, assign(socket, submitted: true, email: email)}

      {:error, _} ->
        # Don't reveal if email exists - always show success
        {:noreply, assign(socket, submitted: true, email: email)}
    end
  end
end
