defmodule TenExTakeHome.MarvelServer do
  use GenServer

  alias TenExTakeHome.Marvel

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name)
  end

  def list_characters(pid_or_name) do
    GenServer.call(pid_or_name, :list_characters)
  end

  @impl true
  def init(_opts) do
    marvel_characters_table = :ets.new(:marvel_characters, [:set, :protected])
    {:ok, characters} =  Marvel.get_characters()

    {:ok, cache_results(characters, marvel_characters_table)}
  end

  @impl true
  def handle_call(:list_characters, _params, marvel_characters_table) do
    {:reply, :ets.tab2list(marvel_characters_table), marvel_characters_table}
  end

  defp cache_results(characters, marvel_characters_table) do
    Enum.each(characters,
      fn result -> :ets.insert_new(marvel_characters_table, {result["id"], result["name"]})
    end)

    marvel_characters_table
  end
end
