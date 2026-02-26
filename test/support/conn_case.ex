defmodule CyaneaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint CyaneaWeb.Endpoint

      use CyaneaWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import CyaneaWeb.ConnCase
    end
  end

  setup tags do
    Cyanea.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Cyanea.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Cyanea.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Extracts the token from a function that receives a URL builder.

  Used to capture tokens sent via email for testing password reset
  and email confirmation flows.
  """
  def extract_user_token(fun) do
    {:ok, token} = fun.(&"#{&1}")
    token
  end

  @doc """
  Creates an API key for the user and sets the Bearer Authorization header.
  Returns the conn with the API auth header set.
  """
  def api_auth_conn(conn, user, opts \\ []) do
    scopes = Keyword.get(opts, :scopes, ["read", "write", "admin"])

    {:ok, _token, raw_token} =
      Cyanea.ApiTokens.create_token(user, %{
        name: "test-token",
        scopes: scopes
      })

    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{raw_token}")
  end

  @doc """
  Encodes a JWT for the user and sets the Bearer Authorization header.
  """
  def jwt_auth_conn(conn, user) do
    {:ok, jwt, _claims} = Cyanea.Guardian.encode_and_sign(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{jwt}")
  end
end
