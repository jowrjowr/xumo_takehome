defmodule XumoWeb.AssetsController do
  use XumoWeb, :controller

  action_fallback XumoWeb.FallbackController

  def index(conn, _params) do
    assets = GenServer.call(Assets, :get_schedule)
    render(conn, "schedule.json", assets: assets)
  end

  # curl http://localhost:4000/api/assets/schedule?asset_id=asset25 -X DELETE -v
  def delete(conn, %{"asset_id" => asset_id}) do
    case GenServer.call(Assets, {:remove_asset, asset_id}) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, :no_asset_found} ->
        send_resp(conn, :not_found, "")
    end
  end

  # curl "http://localhost:4000/api/assets/schedule?scheduled_time=2023-09-02T00:00:00.00Z" -X DELETE -v
  def delete(conn, %{"scheduled_time" => scheduled_time}) do
    {:ok, scheduled_time, _offset} = DateTime.from_iso8601(scheduled_time)

    case GenServer.call(Assets, {:remove_asset, scheduled_time}) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, :no_asset_found} ->
        send_resp(conn, :not_found, "")
    end
  end

  # curl "http://localhost:4000/api/assets/schedule?asset_id=asset25&scheduled_time=2023-09-02T00:00:00.00Z" -X POST
  def insert(conn, %{"asset_id" => asset_id, "scheduled_time" => scheduled_time}) do
    {:ok, scheduled_time, _offset} = DateTime.from_iso8601(scheduled_time)

    case GenServer.call(Assets, {:schedule_asset, asset_id, scheduled_time}) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, :no_asset_found} ->
        send_resp(conn, :not_found, "")
    end
  end
end
