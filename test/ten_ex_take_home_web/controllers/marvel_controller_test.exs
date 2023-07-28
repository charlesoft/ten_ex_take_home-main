defmodule TenExTakeHomeWeb.MarvelControllerTest do
  use TenExTakeHomeWeb.ConnCase

  alias TenExTakeHome.MarvelServer

  describe "index/2" do
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

    test "renders a list of characters", %{conn: conn, bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

      conn = get(conn, Routes.marvel_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Spider-Man"
      assert response =~ "Wolverine"
    end

    test "renders a list of characters based on the given offset", %{conn: conn, bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

      conn = get(conn, Routes.marvel_path(conn, :index, %{"offset" => "1"}))
      response = html_response(conn, 200)

      refute response =~ "Spider-Man"
      assert response =~ "Wolverine"
    end

    test "renders no results if there are failures on the api call", %{
      conn: conn,
      bypass: bypass
    } do
      Bypass.expect(bypass, "GET", "/v1/public/characters", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(@characters_response_body))
      end)

      {:ok, _pid} = MarvelServer.start_link(name: MarvelCharacters)

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

      conn = get(conn, Routes.marvel_path(conn, :index, %{"offset" => "4"}))
      response = html_response(conn, 200)

      refute response =~ "Spider-Man"
      refute response =~ "Wolverine"
    end
  end
end
