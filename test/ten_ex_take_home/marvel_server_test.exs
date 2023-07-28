defmodule TenExTakeHome.MarvelServerTest do
  use TenExTakeHome.DataCase

  alias TenExTakeHome.MarvelServer

  setup do
    bypass = Bypass.open()

    Application.put_env(:ten_ex_take_home, :marvel,
      host: "localhost:#{bypass.port}",
      public_api_key: "test",
      ts: 1,
      hash: "test",
      limit: 2
    )

    {:ok, bypass: bypass}
  end

  describe "list_characters/2" do
    @characters_response_body %{
      "data" => %{
        "results" => [
          %{
            "id" => 1,
            "name" => "Spider-Man"
          },
          %{
            "id" => 2,
            "name" => "Wolverine"
          }
        ]
      },
      "status" => "Ok"
    }

    test "initializes the process caching the table of characters", %{bypass: bypass} do
      assert :ets.whereis(:characters) == :undefined

      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

      assert :ets.whereis(:characters) != :undefined

      assert %{characters: [{1, "Spider-Man"}, {2, "Wolverine"}]} =
               MarvelServer.list_characters(MarvelCharacters, %{})
    end

    test "returns a new list for the given offset when offset is bigger than the cache size", %{
      bypass: bypass
    } do

      # first call
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

      new_characters_response_body = %{
        "data" => %{
          "results" => [
            %{
              "id" => 3,
              "name" => "Iron Man"
            }
          ]
        },
        "status" => "Ok"
      }

      offset = %{"offset" => "2"}

      # second call
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(new_characters_response_body))
      end)

      assert %{characters: [{3, "Iron Man"}]} =
               MarvelServer.list_characters(MarvelCharacters, offset)
    end

    test "does not make a new api call when the offset is lower than the cache size", %{
      bypass: bypass
    } do
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

      offset = %{"offset" => "1"}

      assert %{characters: [{2, "Wolverine"}]} =
               MarvelServer.list_characters(MarvelCharacters, offset)
    end
  end
end
