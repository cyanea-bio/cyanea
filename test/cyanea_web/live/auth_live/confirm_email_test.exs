defmodule CyaneaWeb.AuthLive.ConfirmEmailTest do
  use CyaneaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Cyanea.AccountsFixtures

  alias Cyanea.Accounts

  setup do
    user = unconfirmed_user_fixture()

    token =
      extract_user_token(fn url_fun ->
        Accounts.deliver_user_confirmation_instructions(user, url_fun)
      end)

    %{user: user, token: token}
  end

  describe "Confirm email page" do
    test "confirms user with valid token", %{conn: conn, token: token} do
      result = live(conn, ~p"/auth/confirm-email/#{token}")
      assert {:error, {:redirect, %{to: "/auth/login", flash: %{"info" => info}}}} = result
      assert info =~ "Email confirmed"
    end

    test "rejects invalid token", %{conn: conn} do
      result = live(conn, ~p"/auth/confirm-email/invalid-token")
      assert {:error, {:redirect, %{to: "/auth/login", flash: %{"error" => error}}}} = result
      assert error =~ "invalid or has expired"
    end
  end
end
