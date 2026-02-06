defmodule Cyanea.AccountsTest do
  use Cyanea.DataCase, async: true

  alias Cyanea.Accounts
  alias Cyanea.Accounts.{User, UserToken}

  import Cyanea.AccountsFixtures

  describe "register_user/1" do
    test "creates a user with valid attributes" do
      attrs = valid_user_attributes()
      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == String.downcase(attrs.email)
      assert user.username == attrs.username
      assert user.password_hash != nil
    end

    test "returns error with invalid email" do
      assert {:error, changeset} = Accounts.register_user(%{email: "bad", username: "ok1", password: "password123"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "returns error with duplicate email" do
      attrs = valid_user_attributes()
      assert {:ok, _} = Accounts.register_user(attrs)
      assert {:error, changeset} = Accounts.register_user(%{attrs | username: unique_username()})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "returns error with duplicate username" do
      attrs = valid_user_attributes()
      assert {:ok, _} = Accounts.register_user(attrs)
      assert {:error, changeset} = Accounts.register_user(%{attrs | email: unique_user_email()})
      assert "has already been taken" in errors_on(changeset).username
    end

    test "returns error with short password" do
      assert {:error, changeset} = Accounts.register_user(%{email: unique_user_email(), username: unique_username(), password: "short"})
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end
  end

  describe "authenticate_by_email_password/2" do
    test "returns user with valid credentials" do
      user = user_fixture()
      assert {:ok, authenticated} = Accounts.authenticate_by_email_password(user.email, valid_user_password())
      assert authenticated.id == user.id
    end

    test "returns error with wrong password" do
      user = user_fixture()
      assert {:error, :invalid_credentials} = Accounts.authenticate_by_email_password(user.email, "wrongpassword")
    end

    test "returns error with non-existent email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_by_email_password("nobody@example.com", "password123")
    end
  end

  describe "get_user_by_email/1" do
    test "returns user for existing email" do
      user = user_fixture()
      assert found = Accounts.get_user_by_email(user.email)
      assert found.id == user.id
    end

    test "returns nil for non-existent email" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end
  end

  describe "get_user_by_username/1" do
    test "returns user for existing username" do
      user = user_fixture()
      assert found = Accounts.get_user_by_username(user.username)
      assert found.id == user.id
    end

    test "returns nil for non-existent username" do
      assert Accounts.get_user_by_username("nonexistent") == nil
    end
  end

  describe "get_user_by_orcid/1" do
    test "returns nil when no user has the given ORCID" do
      assert Accounts.get_user_by_orcid("0000-0000-0000-0000") == nil
    end
  end

  describe "find_or_create_oauth_user/1" do
    test "creates a new user when ORCID is not found" do
      attrs = %{
        email: "oauth@example.com",
        username: "oauthuser1",
        name: "OAuth User",
        orcid_id: "0000-0001-2345-6789"
      }

      assert {:ok, %User{} = user} = Accounts.find_or_create_oauth_user(attrs)
      assert user.orcid_id == "0000-0001-2345-6789"
      assert user.email == "oauth@example.com"
    end

    test "returns existing user when ORCID is found" do
      attrs = %{
        email: "oauth@example.com",
        username: "oauthuser2",
        name: "OAuth User",
        orcid_id: "0000-0001-2345-6789"
      }

      {:ok, existing} = Accounts.find_or_create_oauth_user(attrs)
      {:ok, found} = Accounts.find_or_create_oauth_user(%{attrs | email: "other@example.com", username: "other"})
      assert found.id == existing.id
    end
  end

  describe "session tokens" do
    setup do
      %{user: user_fixture()}
    end

    test "generate_user_session_token/1 creates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)

      assert token_record = Repo.get_by(UserToken, context: "session", user_id: user.id)
      assert token_record.token == token
    end

    test "get_user_by_session_token/1 returns user for valid token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert found = Accounts.get_user_by_session_token(token)
      assert found.id == user.id
    end

    test "get_user_by_session_token/1 returns nil for invalid token" do
      assert Accounts.get_user_by_session_token(:crypto.strong_rand_bytes(32)) == nil
    end

    test "get_user_by_session_token/1 returns nil for expired token", %{user: user} do
      {token, user_token} = UserToken.build_session_token(user)
      # Insert with old timestamp
      {1, _} =
        Repo.insert_all(UserToken, [
          %{
            id: Ecto.UUID.generate(),
            token: user_token.token,
            context: "session",
            user_id: user.id,
            inserted_at: DateTime.utc_now() |> DateTime.add(-61, :day) |> DateTime.truncate(:second)
          }
        ])

      refute Accounts.get_user_by_session_token(token)
    end

    test "delete_user_session_token/1 deletes the token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end
end
