defmodule Cyanea.FederationFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Cyanea.Federation` context.
  """

  def unique_node_name, do: "node-#{System.unique_integer([:positive])}"
  def unique_node_url, do: "https://node-#{System.unique_integer([:positive])}.example.com"

  def valid_node_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_node_name(),
      url: unique_node_url()
    })
  end

  def node_fixture(attrs \\ %{}) do
    {:ok, node} =
      attrs
      |> valid_node_attributes()
      |> Cyanea.Federation.register_node()

    node
  end
end
