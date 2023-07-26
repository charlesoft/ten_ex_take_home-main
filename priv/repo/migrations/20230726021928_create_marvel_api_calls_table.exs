defmodule TenExTakeHome.Repo.Migrations.CreateMarvelApiCallsTable do
  use Ecto.Migration

  def change do
    create table(:marvel_api_calls) do
      add :status, :string
      timestamps()
    end
  end
end
