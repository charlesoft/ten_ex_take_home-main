defmodule TenExTakeHomeWeb.MarvelController do
  use TenExTakeHomeWeb, :controller

  alias TenExTakeHome.MarvelServer

  def index(conn, _params) do
    characters = MarvelServer.list_characters(MarvelCharacters)

    conn
    |> put_view(TenExTakeHomeWeb.MarvelView)
    |> render("index.html", characters: characters)
  end
end
