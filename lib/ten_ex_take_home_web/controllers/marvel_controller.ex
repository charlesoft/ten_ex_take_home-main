defmodule TenExTakeHomeWeb.MarvelController do
  use TenExTakeHomeWeb, :controller

  alias TenExTakeHome.MarvelServer

  def index(conn, params) do
    %{characters: characters, offset: offset} =
      MarvelServer.list_characters(MarvelCharacters, params)

    conn
    |> put_view(TenExTakeHomeWeb.MarvelView)
    |> render("index.html", characters: characters, offset: offset, limit: 20)
  end
end
