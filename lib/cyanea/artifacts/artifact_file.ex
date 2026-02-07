defmodule Cyanea.Artifacts.ArtifactFile do
  @moduledoc """
  Join table linking artifacts to their constituent files.

  Each entry maps a logical path within the artifact to a physical
  file record (which in turn references blob storage via S3 key).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "artifact_files" do
    field :path, :string

    belongs_to :artifact, Cyanea.Artifacts.Artifact
    belongs_to :file, Cyanea.Files.File

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(artifact_file, attrs) do
    artifact_file
    |> cast(attrs, [:path, :artifact_id, :file_id])
    |> validate_required([:path, :artifact_id, :file_id])
    |> unique_constraint([:artifact_id, :path])
  end
end
