defmodule Cyanea.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cyanea.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_username, do: "user#{System.unique_integer([:positive])}"
  def valid_user_password, do: "password123"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: unique_username(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Cyanea.Accounts.register_user()

    # Confirm user by default so authenticated tests pass
    confirm_user(user)
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Cyanea.Accounts.register_user()

    user
  end

  defp confirm_user(user) do
    {:ok, user} =
      user
      |> Ecto.Changeset.change(confirmed_at: DateTime.truncate(DateTime.utc_now(), :second))
      |> Cyanea.Repo.update()

    user
  end
end
