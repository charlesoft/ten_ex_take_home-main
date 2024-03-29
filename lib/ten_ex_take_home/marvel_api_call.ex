defmodule TenExTakeHome.MarvelApiCall do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "marvel_api_calls" do
    field :status, :string

    timestamps()
  end

  def changeset(model, attrs \\ %{}) do
    cast(model, attrs, [:status])
  end
end
