defmodule DerbyLiveWeb.AuthLive.MagicLink do
  @moduledoc """
  Handles magic link verification and sign-in.
  """
  use DerbyLiveWeb, :live_view

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sign In")
     |> assign(:token, token)
     |> assign(:error, nil)
     |> assign(:signing_in, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Complete Sign In
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Click the button below to complete your sign in.
          </p>
        </div>

        <%= if @error do %>
          <div class="rounded-md bg-red-50 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  {@error}
                </h3>
                <div class="mt-2">
                  <.link
                    navigate={~p"/sign-in"}
                    class="text-sm font-medium text-red-600 hover:text-red-500"
                  >
                    Request a new magic link →
                  </.link>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="mt-8">
            <button
              phx-click="sign_in"
              disabled={@signing_in}
              class="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <%= if @signing_in do %>
                <svg
                  class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  >
                  </circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
                Signing in...
              <% else %>
                Sign In
              <% end %>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("sign_in", _params, socket) do
    require Logger
    socket = assign(socket, :signing_in, true)
    token = socket.assigns.token

    case AshAuthentication.Jwt.verify(token, :derby_live) do
      {:ok, claims, _resource} ->
        subject = claims["sub"]
        Logger.debug("Magic link verified, subject: #{subject}")

        case AshAuthentication.subject_to_user(subject, DerbyLive.Accounts.User) do
          {:ok, user} ->
            Logger.debug("User loaded: #{user.id}")

            {:ok, session_token, _claims} = AshAuthentication.Jwt.token_for_user(user)

            DerbyLive.Accounts.Token
            |> Ash.Changeset.for_create(:store_token, %{token: session_token, purpose: "user"})
            |> Ash.create!()

            Logger.debug("Token stored, redirecting to callback")

            {:noreply,
             socket
             |> put_flash(:info, "Welcome back!")
             |> redirect(to: ~p"/auth/callback?token=#{session_token}")}

          {:error, error} ->
            Logger.error("Failed to load user from subject: #{inspect(error)}")

            {:noreply,
             assign(socket,
               error: "Unable to sign in. Please try again.",
               signing_in: false
             )}
        end

      :error ->
        {:noreply,
         assign(socket,
           error: "This magic link is invalid or has expired.",
           signing_in: false
         )}
    end
  end
end
