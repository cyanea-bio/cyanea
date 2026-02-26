defmodule Cyanea.Previews.FilePreview do
  @moduledoc """
  Schema for cached file preview data.

  Stores parsed/analyzed preview information so we don't re-download
  and re-parse from S3 on every view.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @preview_types ~w(sequence tabular variant interval structure image pdf markdown text unsupported)

  schema "file_previews" do
    field :preview_type, :string
    field :preview_data, :map, default: %{}
    field :generated_at, :utc_datetime

    belongs_to :blob, Cyanea.Blobs.Blob

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file_preview, attrs) do
    file_preview
    |> cast(attrs, [:blob_id, :preview_type, :preview_data, :generated_at])
    |> validate_required([:blob_id, :preview_type, :generated_at])
    |> validate_inclusion(:preview_type, @preview_types)
    |> unique_constraint(:blob_id)
  end

  def preview_types, do: @preview_types
end
