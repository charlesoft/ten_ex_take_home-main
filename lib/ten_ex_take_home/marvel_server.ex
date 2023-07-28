defmodule TenExTakeHome.MarvelServer do
  @moduledoc """
  GenServer for caching the marvel api call
  """
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

  @impl true
  def init(_opts) do
    characters_table = :ets.new(:characters, [:named_table])
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
    size = :ets.info(characters_table)[:size]
    offset = String.to_integer(offset)

    # check if offset is bigger than the cache size. Otherwise, no need for a new api call
    characters_table =
      if offset > 0 and offset >= size do
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

  defp cache_results(characters, characters_table) do
    Enum.each(
      characters,
      fn result -> :ets.insert_new(characters_table, {result["id"], result["name"]}) end
    )

    characters_table
  end

  defp slice_by_offset(characters_table, offset) do
    range = offset..(offset + get_limit())

    characters_table
    |> get_characters_list()
    |> Enum.slice(range)
  end

  defp get_characters_list(characters_table) do
    :ets.tab2list(characters_table)
  end

  defp get_limit do
    Application.get_env(:ten_ex_take_home, :marvel)[:limit]
  end
end
