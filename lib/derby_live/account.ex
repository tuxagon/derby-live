defmodule DerbyLive.Account do
  alias DerbyLive.Repo
  alias DerbyLive.Account.User
  alias DerbyLive.Account.UserNotifier

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_by_id(id) do
    Repo.get(User, id)
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_auth_token(auth_token) do
    Repo.get_by(User, auth_token: auth_token)
  end

  def get_user_by_api_key(api_key) do
    Repo.get_by(User, api_key: api_key)
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def delete_user(user) do
    Repo.delete(user)
  end

  def reset_auth_token(user) do
    user
    |> User.reset_auth_token_changeset()
    |> Repo.update()
  end

  def send_login_link_email(user) do
    UserNotifier.deliver_login_link(user)
  end
end
