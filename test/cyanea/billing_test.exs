defmodule Cyanea.BillingTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Billing
  alias Cyanea.Billing.Subscription

  import Cyanea.AccountsFixtures
  import Cyanea.BillingFixtures
  import Cyanea.BlobsFixtures
  import Cyanea.OrganizationsFixtures
  import Cyanea.SpacesFixtures

  describe "pro?/1" do
    test "returns false for free user" do
      user = user_fixture()
      refute Billing.pro?(user)
    end

    test "returns true for pro user" do
      user = pro_user_fixture()
      assert Billing.pro?(user)
    end

    test "returns false for free organization" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      refute Billing.pro?(org)
    end

    test "returns true for pro organization" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)

      org
      |> Ecto.Changeset.change(%{plan: "pro"})
      |> Repo.update!()
      |> then(&assert Billing.pro?(&1))
    end
  end

  describe "storage_quota/1" do
    test "returns 1 GB for free user" do
      user = user_fixture()
      assert Billing.storage_quota(user) == 1 * 1_073_741_824
    end

    test "returns 100 GB for pro user" do
      user = pro_user_fixture()
      assert Billing.storage_quota(user) == 100 * 1_073_741_824
    end

    test "returns 2 GB for free organization" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      assert Billing.storage_quota(org) == 2 * 1_073_741_824
    end

    test "returns 1 TB for pro organization" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)

      org =
        org
        |> Ecto.Changeset.change(%{plan: "pro"})
        |> Repo.update!()

      assert Billing.storage_quota(org) == 1_099_511_627_776
    end
  end

  describe "can_have_private_spaces?/1" do
    test "returns false for free user" do
      user = user_fixture()
      refute Billing.can_have_private_spaces?(user)
    end

    test "returns true for pro user" do
      user = pro_user_fixture()
      assert Billing.can_have_private_spaces?(user)
    end
  end

  describe "compute_storage_used/2" do
    test "returns 0 when user has no files" do
      user = user_fixture()
      assert Billing.compute_storage_used("user", user.id) == 0
    end

    test "sums blob sizes for space files" do
      user = user_fixture()
      space = space_fixture(%{owner_type: "user", owner_id: user.id})

      blob1 = blob_fixture(%{content: String.duplicate("a", 1000)})
      blob2 = blob_fixture(%{content: String.duplicate("b", 2000)})

      space_file_fixture(%{space_id: space.id, blob_id: blob1.id})
      space_file_fixture(%{space_id: space.id, blob_id: blob2.id})

      used = Billing.compute_storage_used("user", user.id)
      assert used == blob1.size + blob2.size
    end
  end

  describe "check_storage_quota/2" do
    test "returns :ok when within quota" do
      user = user_fixture()
      assert Billing.check_storage_quota(user, 1000) == :ok
    end

    test "returns error when over quota" do
      user = user_fixture()
      # 1 GB + 1 byte
      over_limit = 1 * 1_073_741_824 + 1
      assert {:error, :storage_quota_exceeded} = Billing.check_storage_quota(user, over_limit)
    end
  end

  describe "storage_info/1" do
    test "returns usage info for display" do
      user = user_fixture()
      info = Billing.storage_info(user)
      assert info.bytes_used == 0
      assert info.quota == 1 * 1_073_741_824
      assert info.percentage == 0.0
    end
  end

  describe "get_active_subscription/2" do
    test "returns nil when no subscription exists" do
      user = user_fixture()
      assert Billing.get_active_subscription("user", user.id) == nil
    end

    test "returns active subscription" do
      user = user_fixture()
      sub = subscription_fixture("user", user.id)

      found = Billing.get_active_subscription("user", user.id)
      assert found.id == sub.id
      assert found.status == "active"
    end

    test "does not return canceled subscription" do
      user = user_fixture()
      _sub = subscription_fixture("user", user.id, %{status: "canceled"})

      assert Billing.get_active_subscription("user", user.id) == nil
    end
  end

  describe "upsert_subscription_from_stripe/1" do
    test "creates subscription and updates plan" do
      user = user_fixture()

      user
      |> Ecto.Changeset.change(%{stripe_customer_id: "cus_test_123"})
      |> Repo.update!()

      stripe_sub = build_stripe_subscription(%{
        id: "sub_test_new",
        customer: "cus_test_123",
        status: "active",
        metadata: %{"owner_type" => "user", "owner_id" => user.id}
      })

      assert {:ok, sub} = Billing.upsert_subscription_from_stripe(stripe_sub)
      assert sub.stripe_subscription_id == "sub_test_new"
      assert sub.status == "active"

      # Plan should be updated
      updated_user = Repo.get!(Cyanea.Accounts.User, user.id)
      assert updated_user.plan == "pro"
    end

    test "is idempotent — updates existing subscription" do
      user = user_fixture()

      user
      |> Ecto.Changeset.change(%{stripe_customer_id: "cus_test_456"})
      |> Repo.update!()

      stripe_sub = build_stripe_subscription(%{
        id: "sub_test_idempotent",
        customer: "cus_test_456",
        status: "active",
        metadata: %{"owner_type" => "user", "owner_id" => user.id}
      })

      assert {:ok, _} = Billing.upsert_subscription_from_stripe(stripe_sub)
      assert {:ok, _} = Billing.upsert_subscription_from_stripe(stripe_sub)

      # Should only have one subscription record
      count =
        from(s in Subscription, where: s.stripe_subscription_id == "sub_test_idempotent")
        |> Repo.aggregate(:count)

      assert count == 1
    end
  end

  describe "handle_subscription_deleted/1" do
    test "sets plan to free" do
      user = pro_user_fixture()

      user
      |> Ecto.Changeset.change(%{stripe_customer_id: "cus_test_del"})
      |> Repo.update!()

      _sub = subscription_fixture("user", user.id, %{stripe_subscription_id: "sub_test_del"})

      stripe_sub = build_stripe_subscription(%{
        id: "sub_test_del",
        customer: "cus_test_del",
        status: "canceled",
        metadata: %{"owner_type" => "user", "owner_id" => user.id}
      })

      assert {:ok, _} = Billing.handle_subscription_deleted(stripe_sub)

      updated_user = Repo.get!(Cyanea.Accounts.User, user.id)
      assert updated_user.plan == "free"
    end
  end

  describe "max_file_size/1" do
    test "returns 50 MB for free user" do
      user = user_fixture()
      assert Billing.max_file_size(user) == 50 * 1_048_576
    end

    test "returns 200 MB for pro user" do
      user = pro_user_fixture()
      assert Billing.max_file_size(user) == 200 * 1_048_576
    end
  end

  describe "check_file_size/2" do
    test "returns :ok when within limit" do
      user = user_fixture()
      assert Billing.check_file_size(user, 10 * 1_048_576) == :ok
    end

    test "returns error when over limit for free user" do
      user = user_fixture()
      assert {:error, :file_too_large} = Billing.check_file_size(user, 51 * 1_048_576)
    end

    test "allows larger files for pro user" do
      user = pro_user_fixture()
      assert Billing.check_file_size(user, 100 * 1_048_576) == :ok
    end
  end

  describe "max_versions_per_notebook/1" do
    test "returns 20 for free user" do
      user = user_fixture()
      assert Billing.max_versions_per_notebook(user) == 20
    end

    test "returns :unlimited for pro user" do
      user = pro_user_fixture()
      assert Billing.max_versions_per_notebook(user) == :unlimited
    end
  end

  describe "can_server_execute?/1" do
    test "returns false for free user" do
      user = user_fixture()
      refute Billing.can_server_execute?(user)
    end

    test "returns true for pro user" do
      user = pro_user_fixture()
      assert Billing.can_server_execute?(user)
    end
  end

  describe "max_org_members/1" do
    test "returns 1 for free org" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      assert Billing.max_org_members(org) == 1
    end

    test "returns 5 for pro org" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)

      org =
        org
        |> Ecto.Changeset.change(%{plan: "pro"})
        |> Repo.update!()

      assert Billing.max_org_members(org) == 5
    end
  end

  describe "check_org_member_limit/1" do
    test "returns error for free org with existing member" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)
      # org already has 1 member (the creator), limit is 1
      assert {:error, :member_limit_reached} = Billing.check_org_member_limit(org)
    end

    test "returns :ok for pro org under limit" do
      user = user_fixture()
      org = organization_fixture(%{}, user.id)

      org =
        org
        |> Ecto.Changeset.change(%{plan: "pro"})
        |> Repo.update!()

      # Pro org has 1 member (creator), limit is 5
      assert Billing.check_org_member_limit(org) == :ok
    end
  end

  describe "limits_for/1" do
    test "returns all limits for free user" do
      user = user_fixture()
      limits = Billing.limits_for(user)

      assert limits.storage_quota == 1 * 1_073_741_824
      assert limits.max_file_size == 50 * 1_048_576
      assert limits.max_versions_per_notebook == 20
      refute limits.can_server_execute
      refute limits.can_have_private_spaces
      assert limits.max_org_members == 1
      assert limits.compute_credits == 0
    end

    test "returns all limits for pro user" do
      user = pro_user_fixture()
      limits = Billing.limits_for(user)

      assert limits.storage_quota == 100 * 1_073_741_824
      assert limits.max_file_size == 200 * 1_048_576
      assert limits.max_versions_per_notebook == :unlimited
      assert limits.can_server_execute
      assert limits.can_have_private_spaces
      assert limits.max_org_members == 5
      assert limits.compute_credits == 1_000
    end
  end

  # Helper to build a fake Stripe.Subscription struct for testing
  defp build_stripe_subscription(attrs) do
    %Stripe.Subscription{
      id: attrs[:id] || "sub_test_#{System.unique_integer([:positive])}",
      customer: attrs[:customer] || "cus_test",
      status: attrs[:status] || "active",
      current_period_start: DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.to_unix(),
      current_period_end: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_unix(),
      cancel_at: nil,
      canceled_at: nil,
      metadata: attrs[:metadata] || %{},
      items: %Stripe.List{
        data: [
          %Stripe.SubscriptionItem{
            price: %Stripe.Price{id: "price_test_pro_user"},
            quantity: 1
          }
        ]
      }
    }
  end
end
