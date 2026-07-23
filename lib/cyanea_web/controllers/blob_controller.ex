defmodule CyaneaWeb.BlobController do
  use CyaneaWeb, :controller

  alias Cyanea.Blobs
  alias Cyanea.Datasets

  def download(conn, %{"id" => id}) do
    blob = Blobs.get_blob!(id)

    case Blobs.download_url(blob) do
      {:ok, url} ->
        count_download(id)
        redirect(conn, external: url)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not generate download URL.")
        |> redirect(to: ~p"/explore")
    end
  end

  # Bump the owning dataset's download counter, if the blob belongs to one.
  # Non-fatal: files not attached to a dataset (e.g. space files) are ignored.
  defp count_download(blob_id) do
    case Datasets.dataset_for_blob(blob_id) do
      %{id: dataset_id} -> Datasets.increment_download_count(dataset_id)
      _ -> :ok
    end
  end
end
