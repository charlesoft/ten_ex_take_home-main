defmodule TenExTakeHome.MarvelApiCall do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "marvel_api_calls" do
    field :status, :string
  end

  def changeset(model, attrs \\ %{}) do
    cast(model, attrs)
  end
end
