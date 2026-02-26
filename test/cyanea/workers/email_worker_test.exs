defmodule Cyanea.Workers.EmailWorkerTest do
  use Cyanea.DataCase, async: false
  use Oban.Testing, repo: Cyanea.Repo

  alias Cyanea.Workers.EmailWorker
  alias Cyanea.Accounts.UserNotifier

  import Cyanea.AccountsFixtures

  describe "enqueue/1" do
    test "enqueues an email job" do
      user = user_fixture()
      email = UserNotifier.confirmation_email(user, "https://example.com/confirm/abc")

      assert {:ok, %Oban.Job{}} = EmailWorker.enqueue(email)
      assert_enqueued(worker: EmailWorker)
    end
  end

  describe "perform/1" do
    test "delivers email via Swoosh test adapter" do
      job = %Oban.Job{
        args: %{
          "to" => "test@example.com",
          "subject" => "Test Subject",
          "text_body" => "Hello, this is a test.",
          "from_name" => "Cyanea",
          "from_address" => "noreply@cyanea.dev"
        }
      }

      assert :ok = EmailWorker.perform(job)
    end
  end
end
