defmodule TenExTakeHome.MarvelServer do
  use GenServer

  alias TenExTakeHome.Marvel

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name)
  end

  def list_characters(pid_or_name, %{"offset" => offset}) do
    GenServer.call(pid_or_name, {:list_characters, offset})
  end

  def list_characters(pid_or_name, _params) do
    GenServer.call(pid_or_name, :list_characters)
  end

  def get_count(pid_or_name) do
    GenServer.call(pid_or_name, :count)
  end

  @impl true
  def init(_opts) do
    characters_table = :ets.new(:characters, [:set, :protected])
    {:ok, characters} = Marvel.get_characters()

    state = %{
      characters_table: cache_results(characters, characters_table),
      offset: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(
        {:list_characters, offset},
        _from,
        %{characters_table: characters_table} = state
      ) do
    count = get_count_table(characters_table)
    offset = String.to_integer(offset)

    characters_table =
      if offset > count do
        {:ok, characters} = Marvel.get_characters(%{offset: offset})

        cache_results(characters, characters_table)
      else
        characters_table
      end

    state =
      state
      |> Map.put(:characters_table, characters_table)
      |> Map.put(:offset, offset)

    result = %{
      characters: slice_by_offset(characters_table, offset),
      offset: offset
    }

    {:reply, result, state}
  end

  def handle_call(
        :list_characters,
        _from,
        %{characters_table: characters_table, offset: offset} = state
      ) do
    result = %{
      characters: get_characters_list(characters_table),
      offset: offset
    }

    {:reply, result, state}
  end

  def handle_call(:count, _from, %{characters_table: characters_table} = state) do
    count = get_count_table(characters_table)

    {:reply, count, state}
  end

  defp cache_results(characters, characters_table) do
    Enum.each(
      characters,
      fn result -> :ets.insert_new(characters_table, {result["id"], result["name"]}) end
    )

    characters_table
  end

  defp slice_by_offset(characters_table, offset) do
    range = (offset - 20)..offset

    characters_table
    |> get_characters_list()
    |> Enum.slice(range)
  end

  defp get_count_table(characters_table) do
    characters_table
    |> get_characters_list()
    |> Enum.count()
  end

  defp get_characters_list(characters_table) do
    :ets.tab2list(characters_table)
  end
end
