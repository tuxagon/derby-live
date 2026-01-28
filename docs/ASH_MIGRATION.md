# Ash Framework Migration Guide

This document explains the migration of DerbyLive from plain Ecto schemas and Phoenix contexts to the Ash Framework ecosystem. It serves as both documentation for this codebase and an educational guide for understanding Ash concepts.

## Table of Contents

1. [What is Ash Framework?](#what-is-ash-framework)
2. [Why Ash?](#why-ash)
3. [Core Concepts](#core-concepts)
4. [AshAuthentication & Magic Links](#ashauthentication--magic-links)
5. [Migration Patterns](#migration-patterns)
6. [Code Examples](#code-examples)
7. [Running the Application](#running-the-application)

---

## What is Ash Framework?

Ash is a **declarative, resource-oriented framework** for building Elixir applications. Instead of writing imperative code that describes *how* to do things, you declare *what* your resources are and Ash generates the behavior.

Think of it like this:
- **Traditional Phoenix**: You write functions like `create_user/1`, `update_user/2`, `list_users/0`
- **Ash**: You declare that User has attributes, actions, and relationships—Ash provides the implementation

### Key Ecosystem Packages

```elixir
# Core Ash Framework
{:ash, "~> 3.0"}

# Data layer for PostgreSQL
{:ash_postgres, "~> 2.0"}

# Phoenix integration (forms, LiveView helpers)
{:ash_phoenix, "~> 2.0"}

# Authentication (magic links, passwords, OAuth)
{:ash_authentication, "~> 4.0"}

# Phoenix auth integration (routes, controllers)
{:ash_authentication_phoenix, "~> 2.0"}
```

---

## Why Ash?

### Before: Phoenix Context Pattern

```elixir
# lib/derby_live/racing.ex (OLD)
defmodule DerbyLive.Racing do
  alias DerbyLive.Repo
  alias DerbyLive.Racing.Event

  def list_events do
    Repo.all(Event)
  end

  def get_event!(id) do
    Repo.get!(Event, id)
  end

  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end
  
  # ... 50+ more functions for each operation
end
```

### After: Ash Resource Pattern

```elixir
# lib/derby_live/racing/event.ex (NEW)
defmodule DerbyLive.Racing.Event do
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "events"
    repo DerbyLive.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :status, :string, default: "live"
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read, :destroy]
    
    create :create do
      accept [:name, :status]
    end
    
    update :update do
      accept [:name, :status]
    end
  end
end
```

### Benefits of Ash

1. **Less Boilerplate**: No need to write CRUD functions manually
2. **Consistent API**: All resources work the same way
3. **Built-in Features**: Pagination, filtering, sorting out of the box
4. **Type Safety**: Compile-time validation of queries and actions
5. **Authorization**: Declarative policies (who can do what)
6. **Extensibility**: Add features via extensions (authentication, admin UIs)

---

## Core Concepts

### 1. Domains (replacing Contexts)

A Domain groups related resources together. In Phoenix terms, it replaces the Context module.

```elixir
# lib/derby_live/racing.ex
defmodule DerbyLive.Racing do
  use Ash.Domain

  resources do
    resource DerbyLive.Racing.Event
    resource DerbyLive.Racing.Racer
    resource DerbyLive.Racing.RacerHeat
  end
end
```

### 2. Resources (replacing Ecto Schemas)

A Resource defines:
- **Attributes**: The data fields (like Ecto schema fields)
- **Relationships**: How resources connect to each other
- **Actions**: What operations can be performed
- **Identities**: Unique constraints
- **Calculations**: Derived/computed values

```elixir
defmodule DerbyLive.Racing.Racer do
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  # Where the data lives
  postgres do
    table "racers"
    repo DerbyLive.Repo
  end

  # The data fields
  attributes do
    integer_primary_key :id
    
    attribute :first_name, :string do
      allow_nil? false
      public? true  # Can be read via API
    end
    
    attribute :last_name, :string do
      allow_nil? false
      public? true
    end
    
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  # How this connects to other resources
  relationships do
    belongs_to :event, DerbyLive.Racing.Event do
      allow_nil? false
      attribute_type :integer  # Match existing DB schema
    end
  end

  # What operations are allowed
  actions do
    defaults [:read, :destroy]
    
    create :create do
      accept [:first_name, :last_name]
      argument :event_id, :integer, allow_nil?: false
      change set_attribute(:event_id, arg(:event_id))
    end
  end

  # Computed values
  calculations do
    calculate :full_name, :string, expr(first_name <> " " <> last_name)
  end
end
```

### 3. Actions

Actions define *what can be done* with a resource. There are four types:

| Type | Purpose |
|------|---------|
| `create` | Insert new records |
| `read` | Query/fetch records |
| `update` | Modify existing records |
| `destroy` | Delete records |

```elixir
actions do
  # Use default implementations
  defaults [:read, :destroy]
  
  # Custom read action with filtering
  read :for_user do
    argument :user_id, :integer, allow_nil?: false
    filter expr(user_id == ^arg(:user_id))
    prepare build(sort: [name: :asc])
  end
  
  # Custom read that returns a single record
  read :by_key do
    argument :key, :string, allow_nil?: false
    get? true  # Returns one record or nil
    filter expr(key == ^arg(:key))
  end
  
  # Create with custom logic
  create :create do
    accept [:name, :status]
    argument :user_id, :integer, allow_nil?: false
    
    change set_attribute(:user_id, arg(:user_id))
    change fn changeset, _context ->
      Ash.Changeset.change_attribute(changeset, :key, generate_key())
    end
  end
  
  # Named update action
  update :archive do
    change set_attribute(:status, "archived")
  end
end
```

### 4. Using Ash in Code

```elixir
# CREATE
{:ok, event} = Ash.create(Event, %{name: "2024 Derby"}, 
  action: :create,
  arguments: %{user_id: current_user.id}
)

# Or with bang version
event = Ash.create!(Event, %{name: "2024 Derby"}, 
  action: :create,
  arguments: %{user_id: current_user.id}
)

# READ (all)
events = Ash.read!(Event)

# READ (with custom action)
events = Event
  |> Ash.Query.for_read(:for_user, %{user_id: user.id})
  |> Ash.read!()

# READ (single record by ID)
event = Ash.get!(Event, event_id)

# READ (with filtering - requires `require Ash.Query`)
require Ash.Query

racers = Racer
  |> Ash.Query.filter(event_id == ^event.id)
  |> Ash.read!()

# UPDATE
{:ok, event} = Ash.update(event, %{name: "New Name"}, action: :update)

# UPDATE (custom action)
{:ok, event} = Ash.update(event, action: :archive)

# DESTROY
:ok = Ash.destroy!(event)

# BULK OPERATIONS
Racer
|> Ash.Query.filter(event_id == ^event.id)
|> Ash.bulk_destroy!(:destroy, %{})
```

---

## AshAuthentication & Magic Links

AshAuthentication provides built-in authentication strategies. We use the **magic link** strategy for passwordless email login.

### How Magic Links Work

1. User enters their email on the sign-in page
2. AshAuthentication generates a JWT token
3. Your `sender` function emails the link to the user
4. User clicks the link
5. AshAuthentication validates the token and creates a session

### Configuration

```elixir
# lib/derby_live/accounts/user.ex
defmodule DerbyLive.Accounts.User do
  use Ash.Resource,
    domain: DerbyLive.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]  # Add the extension

  authentication do
    # Token configuration
    tokens do
      enabled? true
      token_resource DerbyLive.Accounts.Token
      require_token_presence_for_authentication? true
      
      signing_secret fn _, _ ->
        Application.get_env(:derby_live, :token_signing_secret)
      end
    end

    # Authentication strategies
    strategies do
      magic_link do
        identity_field :email
        registration_enabled? true  # Auto-create users
        require_interaction? true   # Prevents auto-link consumption
        
        # Called when a magic link is requested
        sender fn user_or_email, token, _opts ->
          DerbyLive.Accounts.MagicLinkSender.send(user_or_email, token)
        end
      end
    end
  end
  
  # ... rest of resource definition
end
```

### Token Resource

AshAuthentication needs a place to store tokens:

```elixir
# lib/derby_live/accounts/token.ex
defmodule DerbyLive.Accounts.Token do
  use Ash.Resource,
    domain: DerbyLive.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "tokens"
    repo DerbyLive.Repo
  end
end
```

### Sending Magic Links

```elixir
# lib/derby_live/accounts/magic_link_sender.ex
defmodule DerbyLive.Accounts.MagicLinkSender do
  use DerbyLiveWeb, :verified_routes
  import Swoosh.Email
  alias DerbyLive.Mailer

  def send(user_or_email, token) do
    email = get_email(user_or_email)
    url = build_magic_link_url(token)

    new()
    |> to(email)
    |> from({"Derby Live", "noreply@example.com"})
    |> subject("Login to Derby Live")
    |> html_body("""
      <p>Click the link below to login:</p>
      <p><a href="#{url}">Login</a></p>
    """)
    |> Mailer.deliver()

    :ok
  end

  defp get_email(%{email: email}), do: email
  defp get_email(email) when is_binary(email), do: email

  defp build_magic_link_url(token) do
    url(~p"/auth/user/magic_link?token=#{token}")
  end
end
```

### Router Setup

```elixir
# lib/derby_live_web/router.ex
defmodule DerbyLiveWeb.Router do
  use DerbyLiveWeb, :router
  use AshAuthentication.Phoenix.Router  # Add this

  pipeline :browser do
    # ... standard plugs ...
    plug :load_from_session  # Loads current_user from session
  end

  scope "/" do
    pipe_through :browser
    
    # Sign-in page
    sign_in_route(
      register_path: "/register",
      on_mount: [{DerbyLiveWeb.UserAuth, :redirect_if_authenticated}]
    )
    
    # Sign-out
    sign_out_route AuthController
    
    # Magic link callback (user clicks email link)
    magic_sign_in_route(
      DerbyLive.Accounts.User,
      :magic_link,
      auth_routes_prefix: "/auth",
      path: "/auth/user/magic_link"
    )
    
    # OAuth and other auth routes
    auth_routes AuthController, DerbyLive.Accounts.User, path: "/auth"
  end

  # Protected routes
  scope "/" do
    pipe_through :browser
    
    ash_authentication_live_session :require_authenticated_user,
      on_mount: [{DerbyLiveWeb.UserAuth, :ensure_authenticated}] do
      live "/events", EventLive.Index
    end
  end
end
```

---

## Migration Patterns

### From Ecto Changeset to Ash Actions

**Before (Ecto):**
```elixir
def changeset(event, attrs) do
  event
  |> cast(attrs, [:name, :status])
  |> validate_required([:name])
  |> unique_constraint(:key)
end
```

**After (Ash):**
```elixir
actions do
  create :create do
    accept [:name, :status]  # Like cast
    # Validations are automatic based on attribute definitions
    # allow_nil? false acts like validate_required
  end
end

identities do
  identity :unique_key, [:key]  # Like unique_constraint
end
```

### From Context Functions to Ash Queries

**Before:**
```elixir
# In context module
def list_events_for_user(user) do
  from(e in Event, where: e.user_id == ^user.id, order_by: [asc: e.name])
  |> Repo.all()
end
```

**After:**
```elixir
# In resource (as a custom action)
read :for_user do
  argument :user_id, :integer, allow_nil?: false
  filter expr(user_id == ^arg(:user_id))
  prepare build(sort: [name: :asc])
end

# Usage
Event
|> Ash.Query.for_read(:for_user, %{user_id: user.id})
|> Ash.read!()
```

### From LiveView with Context to LiveView with Ash

**Before:**
```elixir
def mount(_params, _session, socket) do
  events = Racing.list_events_for_user(socket.assigns.current_user)
  {:ok, assign(socket, events: events)}
end

def handle_event("delete", %{"id" => id}, socket) do
  event = Racing.get_event!(id)
  {:ok, _} = Racing.delete_event(event)
  {:noreply, stream_delete(socket, :events, event)}
end
```

**After:**
```elixir
def mount(_params, _session, socket) do
  events = Event
    |> Ash.Query.for_read(:for_user, %{user_id: socket.assigns.current_user.id})
    |> Ash.read!()
  {:ok, stream(socket, :events, events)}
end

def handle_event("delete", %{"id" => id}, socket) do
  event = Ash.get!(Event, id)
  :ok = Ash.destroy!(event)
  {:noreply, stream_delete(socket, :events, event)}
end
```

### From Ecto Forms to AshPhoenix Forms

**Before:**
```elixir
def update(%{event: event}, socket) do
  changeset = Racing.change_event(event)
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"event" => params}, socket) do
  case Racing.update_event(socket.assigns.event, params) do
    {:ok, event} -> ...
    {:error, changeset} -> ...
  end
end
```

**After:**
```elixir
def update(%{event: event}, socket) do
  form = 
    if event do
      AshPhoenix.Form.for_update(event, :update, as: "event")
    else
      AshPhoenix.Form.for_create(Event, :create, as: "event")
    end
  {:ok, assign(socket, form: to_form(form))}
end

def handle_event("save", %{"event" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
    {:ok, event} -> ...
    {:error, form} -> ...
  end
end
```

---

## Code Examples

### Complete Resource Example

```elixir
defmodule DerbyLive.Racing.Event do
  use Ash.Resource,
    domain: DerbyLive.Racing,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "events"
    repo DerbyLive.Repo
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :status, :string do
      allow_nil? false
      default "live"
      public? true
    end

    attribute :key, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, DerbyLive.Accounts.User do
      allow_nil? false
      attribute_type :integer
    end

    has_many :racers, DerbyLive.Racing.Racer
    has_many :racer_heats, DerbyLive.Racing.RacerHeat
  end

  identities do
    identity :unique_key, [:key]
  end

  actions do
    defaults [:read, :destroy]

    read :by_key do
      argument :key, :string, allow_nil?: false
      get? true
      filter expr(key == ^arg(:key))
    end

    read :for_user do
      argument :user_id, :integer, allow_nil?: false
      filter expr(user_id == ^arg(:user_id))
      prepare build(sort: [name: :asc])
    end

    create :create do
      accept [:name, :status]
      argument :user_id, :integer, allow_nil?: false
      change set_attribute(:user_id, arg(:user_id))
      change fn changeset, _ ->
        Ash.Changeset.change_attribute(changeset, :key, generate_key())
      end
    end

    update :update do
      accept [:name, :status]
    end

    update :archive do
      change set_attribute(:status, "archived")
    end
  end

  defp generate_key do
    :crypto.strong_rand_bytes(24)
    |> Base.url_encode64(padding: false)
  end
end
```

### LiveView Usage Example

```elixir
defmodule DerbyLiveWeb.EventLive.Index do
  use DerbyLiveWeb, :live_view
  require Ash.Query

  alias DerbyLive.Racing.Event

  def mount(_params, _session, socket) do
    events = Event
      |> Ash.Query.for_read(:for_user, %{user_id: socket.assigns.current_user.id})
      |> Ash.read!()
    
    {:ok, stream(socket, :events, events)}
  end

  def handle_event("archive", %{"id" => id}, socket) do
    event = Ash.get!(Event, id)
    {:ok, event} = Ash.update(event, action: :archive)
    
    {:noreply,
     socket
     |> put_flash(:info, "Event archived")
     |> stream_insert(:events, event)}
  end
end
```

---

## Running the Application

After migration, run these commands:

```bash
# Install dependencies
mix deps.get

# Run the new migrations
mix ecto.migrate

# Start the server
mix phx.server
```

### Key URLs

- **Sign In**: `/sign-in` - Email form for magic link request
- **Sign Out**: `/sign-out` (DELETE)
- **Magic Link Callback**: `/auth/user/magic_link?token=...`
- **Protected Events**: `/events` - Requires authentication

### Development Tips

1. **View emails locally**: Visit `/dev/mailbox` to see sent emails
2. **Debug queries**: Add `Ash.Query.debug()` to print generated SQL
3. **Check token config**: Ensure `token_signing_secret` is set in config

---

## Resources

- [Ash Framework Documentation](https://ash-hq.org/)
- [AshAuthentication Docs](https://hexdocs.pm/ash_authentication/)
- [AshPhoenix Docs](https://hexdocs.pm/ash_phoenix/)
- [AshPostgres Docs](https://hexdocs.pm/ash_postgres/)

