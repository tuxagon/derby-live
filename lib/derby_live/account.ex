defmodule DerbyLive.Account do
  alias DerbyLive.Repo
  alias DerbyLive.Account.User

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_auth_token(auth_token) do
    Repo.get_by(User, auth_token: auth_token)
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
end
