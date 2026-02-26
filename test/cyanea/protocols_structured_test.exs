defmodule Cyanea.ProtocolsStructuredTest do
  use Cyanea.DataCase, async: false

  alias Cyanea.Protocols

  import Cyanea.AccountsFixtures
  import Cyanea.SpacesFixtures
  import Cyanea.ProtocolsFixtures

  setup do
    user = user_fixture()
    space = space_fixture(%{owner_type: "user", owner_id: user.id})

    protocol =
      protocol_fixture(%{
        space_id: space.id,
        content: %{
          "materials" => [],
          "equipment" => [],
          "steps" => [],
          "tips" => ""
        }
      })

    %{protocol: protocol, space: space, user: user}
  end

  describe "update_materials/2" do
    test "replaces materials in content", %{protocol: protocol} do
      materials = [
        %{"name" => "Taq Polymerase", "quantity" => "1 uL", "vendor" => "NEB", "catalog_number" => "M0273"},
        %{"name" => "dNTPs", "quantity" => "0.5 uL", "vendor" => "NEB", "catalog_number" => "N0447"}
      ]

      {:ok, updated} = Protocols.update_materials(protocol, materials)
      assert length(Protocols.get_materials(updated)) == 2
      assert hd(Protocols.get_materials(updated))["name"] == "Taq Polymerase"
    end

    test "preserves other sections", %{protocol: protocol} do
      {:ok, protocol} = Protocols.update_tips(protocol, "Some tips")
      {:ok, updated} = Protocols.update_materials(protocol, [%{"name" => "Buffer"}])

      assert Protocols.get_tips(updated) == "Some tips"
      assert length(Protocols.get_materials(updated)) == 1
    end
  end

  describe "update_equipment/2" do
    test "replaces equipment in content", %{protocol: protocol} do
      equipment = [
        %{"name" => "Thermocycler", "settings" => "Standard PCR", "notes" => ""}
      ]

      {:ok, updated} = Protocols.update_equipment(protocol, equipment)
      assert length(Protocols.get_equipment(updated)) == 1
      assert hd(Protocols.get_equipment(updated))["name"] == "Thermocycler"
    end
  end

  describe "update_steps/2" do
    test "auto-numbers steps", %{protocol: protocol} do
      steps = [
        %{"description" => "Prepare master mix", "duration" => "5 min", "temperature" => "4C"},
        %{"description" => "Run PCR program", "duration" => "2 hr", "temperature" => "varies"}
      ]

      {:ok, updated} = Protocols.update_steps(protocol, steps)
      steps = Protocols.get_steps(updated)

      assert length(steps) == 2
      assert Enum.at(steps, 0)["number"] == 1
      assert Enum.at(steps, 1)["number"] == 2
    end

    test "renumbers after reorder", %{protocol: protocol} do
      steps = [
        %{"description" => "Step A"},
        %{"description" => "Step B"},
        %{"description" => "Step C"}
      ]

      {:ok, protocol} = Protocols.update_steps(protocol, steps)

      # Reorder: remove first, add at end
      reordered = [
        %{"description" => "Step B"},
        %{"description" => "Step C"},
        %{"description" => "Step A"}
      ]

      {:ok, updated} = Protocols.update_steps(protocol, reordered)
      result = Protocols.get_steps(updated)

      assert Enum.at(result, 0)["number"] == 1
      assert Enum.at(result, 0)["description"] == "Step B"
      assert Enum.at(result, 2)["number"] == 3
    end
  end

  describe "update_tips/2" do
    test "replaces tips content", %{protocol: protocol} do
      {:ok, updated} = Protocols.update_tips(protocol, "If bands are faint, increase template.")
      assert Protocols.get_tips(updated) == "If bands are faint, increase template."
    end
  end

  describe "bump_version/2" do
    test "bumps patch version", %{protocol: protocol} do
      assert protocol.version == "1.0.0"
      {:ok, bumped} = Protocols.bump_version(protocol, :patch)
      assert bumped.version == "1.0.1"
    end

    test "bumps minor version and resets patch", %{protocol: protocol} do
      {:ok, bumped} = Protocols.bump_version(protocol, :minor)
      assert bumped.version == "1.1.0"
    end

    test "bumps major version and resets minor/patch", %{protocol: protocol} do
      {:ok, bumped} = Protocols.bump_version(protocol, :major)
      assert bumped.version == "2.0.0"
    end

    test "successive bumps", %{protocol: protocol} do
      {:ok, p} = Protocols.bump_version(protocol, :patch)
      {:ok, p} = Protocols.bump_version(p, :patch)
      assert p.version == "1.0.2"

      {:ok, p} = Protocols.bump_version(p, :minor)
      assert p.version == "1.1.0"
    end
  end

  describe "content accessors" do
    test "get_materials returns empty list for nil content" do
      protocol = %Cyanea.Protocols.Protocol{content: nil}
      assert Protocols.get_materials(protocol) == []
    end

    test "get_steps returns empty list for empty content" do
      protocol = %Cyanea.Protocols.Protocol{content: %{}}
      assert Protocols.get_steps(protocol) == []
    end
  end

  describe "change_protocol/2" do
    test "returns a changeset", %{protocol: protocol} do
      changeset = Protocols.change_protocol(protocol)
      assert %Ecto.Changeset{} = changeset
    end
  end
end
