defmodule XumoWeb.AssetsView do
  use XumoWeb, :view
  alias XumoWeb.AssetsView

  def render("schedule.json", %{assets: assets}) do
    render_many(assets, AssetsView, "item_schedule.json")
  end

  def render("item_schedule.json", %{assets: {scheduled_time, asset}}) do
    %{
      scheduled_time: scheduled_time,
      asset_id: asset.id
    }
  end
end
