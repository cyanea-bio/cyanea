defmodule CyaneaWeb.FileController do
  use CyaneaWeb, :controller

  alias Cyanea.Files
  alias Cyanea.Repositories

  def download(conn, %{"id" => id}) do
    file = Files.get_file!(id)
    repo = Repositories.get_repository!(file.repository_id)
    current_user = conn.assigns[:current_user]

    if Repositories.can_access?(repo, current_user) do
      case Files.download_url(file) do
        {:ok, url} ->
          redirect(conn, external: url)

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Could not generate download URL.")
          |> redirect(to: ~p"/explore")
      end
    else
      conn
      |> put_status(:forbidden)
      |> put_flash(:error, "You don't have access to this file.")
      |> redirect(to: ~p"/explore")
    end
  end
end
