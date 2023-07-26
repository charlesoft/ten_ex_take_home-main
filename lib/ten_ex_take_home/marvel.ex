defmodule TenExTakeHome.Marvel do
  @default_offset 0

  def get_characters(params \\ %{}) do
    offset = Map.get(params, :offset)
    offset = if is_nil(offset), do: @default_offset, else: offset

    [host: host, public_api_key: public_api_key, ts: ts, hash: hash] = get_api_credentials()

    case HTTPoison.get(
           "#{host}/v1/public/characters?ts=#{ts}&apikey=#{public_api_key}&hash=#{hash}&offset=#{offset}"
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"data" => %{"results" => results}} = Jason.decode!(body)

        {:ok, results}

      {:error, _error} ->
        {:ok, []}
    end
  end

  defp get_api_credentials do
    Application.get_env(:ten_ex_take_home, :marvel)
  end
end
