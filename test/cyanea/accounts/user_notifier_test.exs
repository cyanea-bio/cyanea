defmodule Cyanea.Accounts.UserNotifierTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Accounts.UserNotifier

  import Cyanea.AccountsFixtures

  describe "confirmation_email/2" do
    test "builds confirmation email with correct fields" do
      user = user_fixture(%{name: "Jane Doe"})
      url = "https://cyanea.dev/auth/confirm/abc123"

      email = UserNotifier.confirmation_email(user, url)

      assert email.subject == "Confirm your Cyanea account"
      assert {_name, to_address} = hd(email.to)
      assert to_address == user.email
      assert email.text_body =~ url
      assert email.text_body =~ "Jane Doe"
      assert email.text_body =~ "expire in 24 hours"
    end

    test "falls back to username when name is nil" do
      user = user_fixture()
      email = UserNotifier.confirmation_email(user, "https://example.com/confirm")

      assert email.text_body =~ user.username
    end
  end

  describe "reset_password_email/2" do
    test "builds reset email with correct fields" do
      user = user_fixture(%{name: "John Smith"})
      url = "https://cyanea.dev/auth/reset/xyz789"

      email = UserNotifier.reset_password_email(user, url)

      assert email.subject == "Reset your Cyanea password"
      assert {_name, to_address} = hd(email.to)
      assert to_address == user.email
      assert email.text_body =~ url
      assert email.text_body =~ "John Smith"
      assert email.text_body =~ "expire in 24 hours"
    end
  end
end
