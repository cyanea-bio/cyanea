defmodule Cyanea.ProtocolsTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Protocols
  alias Cyanea.Protocols.Protocol

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.ProtocolsFixtures

  defp setup_space(_context) do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})
    %{user: user, space: space}
  end

  describe "create_protocol/1" do
    setup :setup_space

    test "creates a protocol", %{space: space} do
      attrs = valid_protocol_attributes(%{space_id: space.id})
      assert {:ok, protocol} = Protocols.create_protocol(attrs)
      assert protocol.title == attrs.title
      assert protocol.slug == attrs.slug
      assert protocol.version == "1.0.0"
      assert protocol.space_id == space.id
    end

    test "enforces unique slug per space", %{space: space} do
      attrs = valid_protocol_attributes(%{space_id: space.id, slug: "unique-slug"})
      assert {:ok, _} = Protocols.create_protocol(attrs)
      assert {:error, changeset} = Protocols.create_protocol(attrs)
      assert errors_on(changeset)[:slug]
    end

    test "validates version format", %{space: space} do
      attrs = valid_protocol_attributes(%{space_id: space.id, version: "bad"})
      assert {:error, changeset} = Protocols.create_protocol(attrs)
      assert errors_on(changeset)[:version]
    end

    test "accepts valid semantic version", %{space: space} do
      attrs = valid_protocol_attributes(%{space_id: space.id, version: "2.1.0"})
      assert {:ok, protocol} = Protocols.create_protocol(attrs)
      assert protocol.version == "2.1.0"
    end
  end

  describe "list_space_protocols/1" do
    setup :setup_space

    test "lists protocols for a space", %{space: space} do
      _p1 = protocol_fixture(%{space_id: space.id})
      _p2 = protocol_fixture(%{space_id: space.id})

      protocols = Protocols.list_space_protocols(space.id)
      assert length(protocols) == 2
    end

    test "does not return protocols from other spaces", %{user: user, space: space} do
      other_space = space_fixture(%{owner_type: "user", owner_id: user.id})
      _p = protocol_fixture(%{space_id: other_space.id})

      assert Protocols.list_space_protocols(space.id) == []
    end
  end

  describe "get_protocol!/1" do
    setup :setup_space

    test "returns the protocol", %{space: space} do
      protocol = protocol_fixture(%{space_id: space.id})
      found = Protocols.get_protocol!(protocol.id)
      assert found.id == protocol.id
    end

    test "raises for non-existent ID" do
      assert_raise Ecto.NoResultsError, fn ->
        Protocols.get_protocol!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_protocol_by_slug/2" do
    setup :setup_space

    test "returns protocol for valid space and slug", %{space: space} do
      protocol = protocol_fixture(%{space_id: space.id})
      found = Protocols.get_protocol_by_slug(space.id, protocol.slug)
      assert found.id == protocol.id
    end

    test "returns nil for non-existent slug", %{space: space} do
      assert Protocols.get_protocol_by_slug(space.id, "nonexistent") == nil
    end
  end

  describe "update_protocol/2" do
    setup :setup_space

    test "updates fields", %{space: space} do
      protocol = protocol_fixture(%{space_id: space.id})
      assert {:ok, updated} = Protocols.update_protocol(protocol, %{description: "new desc"})
      assert updated.description == "new desc"
    end

    test "updates version", %{space: space} do
      protocol = protocol_fixture(%{space_id: space.id})
      assert {:ok, updated} = Protocols.update_protocol(protocol, %{version: "2.0.0"})
      assert updated.version == "2.0.0"
    end
  end

  describe "delete_protocol/1" do
    setup :setup_space

    test "deletes the protocol", %{space: space} do
      protocol = protocol_fixture(%{space_id: space.id})
      assert {:ok, _} = Protocols.delete_protocol(protocol)

      assert_raise Ecto.NoResultsError, fn ->
        Protocols.get_protocol!(protocol.id)
      end
    end
  end
end
