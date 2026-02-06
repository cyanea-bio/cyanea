defmodule Cyanea.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cyanea.Organizations` context.
  """

  def unique_org_name, do: "Org #{System.unique_integer([:positive])}"
  def unique_org_slug, do: "org-#{System.unique_integer([:positive])}"

  def valid_org_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_org_name(),
      slug: unique_org_slug(),
      description: "A test organization"
    })
  end

  def organization_fixture(attrs \\ %{}, creator_user_id) do
    {:ok, organization} =
      attrs
      |> valid_org_attributes()
      |> Cyanea.Organizations.create_organization(creator_user_id)

    organization
  end
end
