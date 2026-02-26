defmodule Cyanea.StarsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Spaces
  alias Cyanea.Stars

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.StarsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "star_space/2" do
    setup :setup_space

    test "creates a star", %{space: space} do
      starrer = user_fixture()
      assert {:ok, star} = Stars.star_space(starrer.id, space.id)
      assert star.user_id == starrer.id
      assert star.space_id == space.id
    end

    test "increments space star_count", %{space: space} do
      starrer = user_fixture()
      {:ok, _} = Stars.star_space(starrer.id, space.id)

      updated_space = Spaces.get_space!(space.id)
      assert updated_space.star_count == 1
    end

    test "cannot star same space twice", %{space: space} do
      starrer = user_fixture()
      assert {:ok, _} = Stars.star_space(starrer.id, space.id)
      assert {:error, _changeset} = Stars.star_space(starrer.id, space.id)
    end
  end

  describe "unstar_space/2" do
    setup :setup_space

    test "removes star", %{space: space} do
      starrer = user_fixture()
      {:ok, _} = Stars.star_space(starrer.id, space.id)
      assert :ok = Stars.unstar_space(starrer.id, space.id)
      refute Stars.starred?(starrer.id, space.id)
    end

    test "decrements star_count", %{space: space} do
      starrer = user_fixture()
      {:ok, _} = Stars.star_space(starrer.id, space.id)
      :ok = Stars.unstar_space(starrer.id, space.id)

      updated_space = Spaces.get_space!(space.id)
      assert updated_space.star_count == 0
    end

    test "returns error when not starred", %{space: space} do
      user = user_fixture()
      assert {:error, :not_starred} = Stars.unstar_space(user.id, space.id)
    end
  end

  describe "starred?/2" do
    setup :setup_space

    test "returns true when starred", %{space: space} do
      starrer = user_fixture()
      {:ok, _} = Stars.star_space(starrer.id, space.id)
      assert Stars.starred?(starrer.id, space.id) == true
    end

    test "returns false when not starred", %{space: space} do
      user = user_fixture()
      assert Stars.starred?(user.id, space.id) == false
    end
  end

  describe "list_user_stars/2" do
    setup :setup_space

    test "lists starred spaces", %{user: user, space: space} do
      starrer = user_fixture()
      space2 = space_fixture(%{owner_type: "user", owner_id: user.id})

      {:ok, _} = Stars.star_space(starrer.id, space.id)
      {:ok, _} = Stars.star_space(starrer.id, space2.id)

      stars = Stars.list_user_stars(starrer.id)
      assert length(stars) == 2
      assert hd(stars).space != nil
    end

    test "returns empty list for user with no stars" do
      user = user_fixture()
      assert Stars.list_user_stars(user.id) == []
    end
  end
end
