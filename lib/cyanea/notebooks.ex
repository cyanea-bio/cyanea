defmodule Cyanea.Notebooks do
  @moduledoc """
  The Notebooks context — computational notebooks within spaces.
  """
  import Ecto.Query

  alias Cyanea.Notebooks.Notebook
  alias Cyanea.Repo

  ## Listing

  @doc """
  Lists notebooks in a space, ordered by position then title.
  """
  def list_space_notebooks(space_id) do
    from(n in Notebook,
      where: n.space_id == ^space_id,
      order_by: [asc: n.position, asc: n.title]
    )
    |> Repo.all()
  end

  ## Fetching

  @doc """
  Gets a single notebook by ID. Raises if not found.
  """
  def get_notebook!(id), do: Repo.get!(Notebook, id)

  @doc """
  Gets a notebook by space ID and slug.
  """
  def get_notebook_by_slug(space_id, slug) do
    Repo.get_by(Notebook, space_id: space_id, slug: String.downcase(slug))
  end

  ## Create / Update / Delete

  @doc """
  Creates a notebook in a space.
  """
  def create_notebook(attrs) do
    %Notebook{}
    |> Notebook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notebook.
  """
  def update_notebook(%Notebook{} = notebook, attrs) do
    notebook
    |> Notebook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notebook.
  """
  def delete_notebook(%Notebook{} = notebook) do
    Repo.delete(notebook)
  end

  @doc """
  Returns a changeset for tracking notebook changes in forms.
  """
  def change_notebook(%Notebook{} = notebook, attrs \\ %{}) do
    Notebook.changeset(notebook, attrs)
  end

  ## Cell Management

  @doc """
  Adds a cell to a notebook at the given position.

  If position is nil, appends to the end.
  """
  def add_cell(%Notebook{} = notebook, type, position \\ nil) do
    cells = get_cells(notebook)
    position = position || length(cells)

    new_cell = %{
      "id" => Ecto.UUID.generate(),
      "type" => to_string(type),
      "source" => "",
      "position" => position
    }

    new_cell =
      if type in ["code", :code] do
        Map.put(new_cell, "language", "cyanea")
      else
        new_cell
      end

    cells =
      cells
      |> List.insert_at(position, new_cell)
      |> reindex_positions()

    update_notebook(notebook, %{content: %{"cells" => cells}})
  end

  @doc """
  Removes a cell from a notebook by cell ID.
  """
  def remove_cell(%Notebook{} = notebook, cell_id) do
    cells =
      notebook
      |> get_cells()
      |> Enum.reject(&(&1["id"] == cell_id))
      |> reindex_positions()

    update_notebook(notebook, %{content: %{"cells" => cells}})
  end

  @doc """
  Updates a cell's attributes (source, language, etc.).
  """
  def update_cell(%Notebook{} = notebook, cell_id, attrs) do
    cells =
      notebook
      |> get_cells()
      |> Enum.map(fn cell ->
        if cell["id"] == cell_id do
          Map.merge(cell, stringify_keys(attrs))
        else
          cell
        end
      end)

    update_notebook(notebook, %{content: %{"cells" => cells}})
  end

  @doc """
  Moves a cell up or down by one position.
  """
  def move_cell(%Notebook{} = notebook, cell_id, direction) when direction in [:up, :down] do
    cells = get_cells(notebook)
    idx = Enum.find_index(cells, &(&1["id"] == cell_id))

    cond do
      is_nil(idx) ->
        {:ok, notebook}

      direction == :up and idx == 0 ->
        {:ok, notebook}

      direction == :down and idx == length(cells) - 1 ->
        {:ok, notebook}

      true ->
        swap_idx = if direction == :up, do: idx - 1, else: idx + 1

        cells =
          cells
          |> List.replace_at(idx, Enum.at(cells, swap_idx))
          |> List.replace_at(swap_idx, Enum.at(cells, idx))
          |> reindex_positions()

        update_notebook(notebook, %{content: %{"cells" => cells}})
    end
  end

  @doc """
  Returns the list of cells from a notebook's content.
  """
  def get_cells(%Notebook{content: content}) when is_map(content) do
    Map.get(content, "cells", [])
  end

  def get_cells(%Notebook{}), do: []

  @doc """
  Returns true if the cell is an executable cyanea code cell.
  """
  def executable_cell?(%{"type" => "code", "language" => "cyanea"}), do: true
  def executable_cell?(_), do: false

  defp reindex_positions(cells) do
    cells
    |> Enum.with_index()
    |> Enum.map(fn {cell, idx} -> Map.put(cell, "position", idx) end)
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
