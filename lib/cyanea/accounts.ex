defmodule Cyanea.Accounts do
  @moduledoc """
  The Accounts context - user management and authentication.
  """
  alias Cyanea.Repo
  alias Cyanea.Accounts.{User, UserToken}

  @doc """
  Gets a user by ID.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: String.downcase(username))
  end

  @doc """
  Gets a user by ORCID ID.
  """
  def get_user_by_orcid(orcid_id) when is_binary(orcid_id) do
    Repo.get_by(User, orcid_id: orcid_id)
  end

  @doc """
  Registers a new user.
  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Cyanea.Search.index_user(user)
        {:ok, user}

      error ->
        error
    end
  end

  @doc """
  Registers or updates a user from OAuth.
  """
  def find_or_create_oauth_user(attrs) do
    case get_user_by_orcid(attrs.orcid_id) do
      nil ->
        # Check if email matches existing user — auto-link (ORCID is trusted)
        existing = if attrs[:email], do: get_user_by_email(attrs.email)

        if existing do
          link_orcid(existing, attrs.orcid_id)
        else
          %User{}
          |> User.oauth_changeset(attrs)
          |> Repo.insert()
        end

      user ->
        {:ok, user}
    end
  end

  @doc """
  Links an ORCID iD to an existing user.
  Returns `{:error, :already_linked}` if user already has an ORCID,
  `{:error, :orcid_taken}` if the ORCID belongs to another user.
  """
  def link_orcid(%User{} = user, orcid_id) do
    cond do
      user.orcid_id == orcid_id ->
        {:error, :already_linked}

      user.orcid_id != nil ->
        {:error, :already_linked}

      get_user_by_orcid(orcid_id) != nil ->
        {:error, :orcid_taken}

      true ->
        user
        |> Ecto.Changeset.change(orcid_id: orcid_id)
        |> Repo.update()
    end
  end

  @doc """
  Unlinks ORCID from user. Fails if user has no password set (would lock them out).
  """
  def unlink_orcid(%User{} = user) do
    if is_nil(user.password_hash) do
      {:error, :no_password}
    else
      user
      |> Ecto.Changeset.change(orcid_id: nil)
      |> Repo.update()
    end
  end

  @doc """
  Authenticates a user by email and password.
  """
  def authenticate_by_email_password(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Cyanea.Search.index_user(user)
        {:ok, user}

      error ->
        error
    end
  end

  @doc """
  Returns a changeset for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Email verification

  @doc """
  Delivers the confirmation email instructions to the given user.
  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      # TODO: Send email via Swoosh/Oban
      {:ok, encoded_token}
    end
  end

  @doc """
  Confirms a user by the given token.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, Ecto.Changeset.change(user, confirmed_at: DateTime.truncate(DateTime.utc_now(), :second)))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Password reset

  @doc """
  Delivers the reset password email to the given user.
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    # TODO: Send email via Swoosh/Oban
    {:ok, encoded_token}
  end

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
