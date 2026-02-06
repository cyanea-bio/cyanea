defmodule Cyanea.Organizations do
  @moduledoc """
  The Organizations context - managing organizations, memberships, and teams.
  """
  import Ecto.Query

  alias Cyanea.Repo
  alias Cyanea.Organizations.{Organization, Membership}

  @role_levels %{"owner" => 4, "admin" => 3, "member" => 2, "viewer" => 1}

  ## Organizations

  @doc """
  Lists organizations a user belongs to.
  """
  def list_user_organizations(user_id) do
    from(o in Organization,
      join: m in Membership,
      on: m.organization_id == o.id,
      where: m.user_id == ^user_id,
      order_by: [asc: o.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single organization by ID.

  Raises `Ecto.NoResultsError` if the Organization does not exist.
  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Gets an organization by slug.
  """
  def get_organization_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Organization, slug: String.downcase(slug))
  end

  @doc """
  Returns a changeset for tracking organization changes.
  """
  def change_organization(%Organization{} = org, attrs \\ %{}) do
    Organization.changeset(org, attrs)
  end

  @doc """
  Creates an organization and adds the creator as owner.
  """
  def create_organization(attrs, creator_user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:organization, Organization.changeset(%Organization{}, attrs))
    |> Ecto.Multi.insert(:membership, fn %{organization: org} ->
      Membership.changeset(%Membership{}, %{
        user_id: creator_user_id,
        organization_id: org.id,
        role: "owner"
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: org}} -> {:ok, org}
      {:error, :organization, changeset, _} -> {:error, changeset}
      {:error, :membership, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates an organization.
  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an organization and all associated data.
  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  ## Authorization

  @doc """
  Checks if a user has at least the given role in an organization.
  Returns `{:ok, membership}` or `{:error, :unauthorized}`.
  """
  def authorize(user_id, org_id, minimum_role) do
    case get_membership(user_id, org_id) do
      nil ->
        {:error, :unauthorized}

      membership ->
        if role_level(membership.role) >= role_level(minimum_role) do
          {:ok, membership}
        else
          {:error, :unauthorized}
        end
    end
  end

  defp role_level(role), do: Map.get(@role_levels, role, 0)

  ## Memberships

  @doc """
  Gets a user's membership in an organization.
  Returns nil if the user is not a member.
  """
  def get_membership(user_id, organization_id) do
    Repo.get_by(Membership, user_id: user_id, organization_id: organization_id)
  end

  @doc """
  Lists all members of an organization with their user data.
  """
  def list_members(organization_id) do
    from(m in Membership,
      where: m.organization_id == ^organization_id,
      join: u in assoc(m, :user),
      preload: [user: u],
      order_by: [asc: u.username]
    )
    |> Repo.all()
  end

  @doc """
  Adds a member to an organization.
  """
  def add_member(org_id, user_id, role \\ "member") do
    %Membership{}
    |> Membership.changeset(%{organization_id: org_id, user_id: user_id, role: role})
    |> Repo.insert()
  end

  @doc """
  Updates a membership's role. Guards against removing the last owner.
  """
  def update_membership_role(%Membership{} = membership, new_role) do
    if membership.role == "owner" and new_role != "owner" do
      owner_count = count_owners(membership.organization_id)

      if owner_count <= 1 do
        {:error, :last_owner}
      else
        membership
        |> Membership.changeset(%{role: new_role})
        |> Repo.update()
      end
    else
      membership
      |> Membership.changeset(%{role: new_role})
      |> Repo.update()
    end
  end

  @doc """
  Removes a member from an organization. Guards against removing the last owner.
  """
  def remove_member(%Membership{} = membership) do
    if membership.role == "owner" do
      owner_count = count_owners(membership.organization_id)

      if owner_count <= 1 do
        {:error, :last_owner}
      else
        Repo.delete(membership)
      end
    else
      Repo.delete(membership)
    end
  end

  defp count_owners(org_id) do
    from(m in Membership,
      where: m.organization_id == ^org_id and m.role == "owner",
      select: count(m.id)
    )
    |> Repo.one()
  end
end
