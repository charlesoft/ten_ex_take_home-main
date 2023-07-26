defmodule TenExTakeHome.MarvelTest do
  use TenExTakeHome.DataCase

  alias TenExTakeHome.{Marvel, MarvelApiCall, Repo}

  setup do
    bypass = Bypass.open()

    Application.put_env(:ten_ex_take_home, :marvel,
      host: "localhost:#{bypass.port}",
      public_api_key: "test",
      ts: 1,
      hash: "test"
    )

    {:ok, bypass: bypass}
  end

  describe "get_characters/1" do
    test "returns a list of characters", %{bypass: bypass} do
      characters_response_body =
        %{
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
        |> Jason.encode!()

      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, characters_response_body)
      end)

      assert {:ok,
              [
                %{"id" => 1, "name" => "Spider-Man"},
                %{"id" => 2, "name" => "Wolverine"}
              ]} = Marvel.get_characters()
    end

    test "returns an error given invalid credentials", %{bypass: bypass} do
      response_body =
        %{
          "code" => "InvalidCredentials",
          "message" => "That hash, timestamp and key combination is invalid."
        }
        |> Jason.encode!()

      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(401, response_body)
      end)

      assert {:error,
              %{
                "code" => "InvalidCredentials",
                "message" => "That hash, timestamp and key combination is invalid."
              }} = Marvel.get_characters()
    end

    test "creates a marvel api call after a sucessful request", %{bypass: bypass} do
      assert [] == Repo.all(MarvelApiCall)

      response_body = %{"data" => %{"results" => []}, "status" => "Ok"} |> Jason.encode!()

      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      Marvel.get_characters()

      assert [%MarvelApiCall{status: "Ok"}] = Repo.all(MarvelApiCall)
    end

    test "creates a marvel api call after a unsucessful request", %{bypass: bypass} do
      assert [] == Repo.all(MarvelApiCall)

      response_body =
        %{
          "code" => "InvalidCredentials",
          "message" => "That hash, timestamp and key combination is invalid."
        }
        |> Jason.encode!()

      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(401, response_body)
      end)

      Marvel.get_characters()

      assert [%MarvelApiCall{status: "InvalidCredentials"}] = Repo.all(MarvelApiCall)
    end
  end
end
