defmodule Xumo.Assets do
  use GenServer
  require Logger

  @enforce_keys [:description, :duration, :id, :image_url, :title, :upload_date]
  @optional_keys []

  @type t :: %__MODULE__{
          id: String.t(),
          description: String.t(),
          duration: integer(),
          image_url: String.t(),
          title: String.t(),
          upload_date: DateTime.t()
        }

  defstruct @enforce_keys ++ @optional_keys

  @spec start_link(list()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: Assets)
  end

  @impl true
  @spec init(any) :: {:ok, map()}
  def init(_) do
    assets = fetch_assets()

    state = %{
      assets: assets,
      schedule: %{}
    }

    {:ok, state}
  end

  # recompile(); Xumo.Assets.fetch_assets()
  # recompile(); GenServer.call(Assets, {:schedule_asset, "asset25", ~U[2023-09-02 0:00:00Z]})
  # GenServer.call(Assets, {:remove_asset, ~U[2023-09-02 00:00:00.00Z]})

  @impl true
  def handle_call(
        {:remove_asset, %DateTime{} = target_timestamp},
        _from,
        %{schedule: schedule} = state
      ) do
    # first need to locate the asset by timestamp

    target_asset =
      schedule
      |> Map.to_list()
      |> Enum.filter(fn {timestamp, _asset} -> timestamp == target_timestamp end)
      |> Enum.map(fn {_timestamp, asset} -> asset end)

    case target_asset do
      [%Xumo.Assets{id: asset_id}] ->
        # the asset ID has been located. purge it all.
        scheduled_time_blocks =
          schedule
          |> Map.to_list()
          |> Enum.filter(fn {_timestamp, asset} -> asset.id == asset_id end)
          |> Enum.map(fn {timestamp, _asset} -> timestamp end)

        new_schedule = Map.drop(schedule, scheduled_time_blocks)

        state = Map.replace(state, :schedule, new_schedule)
        {:reply, :ok, state}

      [] ->
        {:reply, {:error, :no_asset_found}, state}
    end
  end

  def handle_call({:remove_asset, asset_id}, _from, %{schedule: schedule} = state) do
    scheduled_time_blocks =
      schedule
      |> Map.to_list()
      |> Enum.filter(fn {_timestamp, asset} -> asset.id == asset_id end)
      |> Enum.map(fn {timestamp, _asset} -> timestamp end)

    new_schedule = Map.drop(schedule, scheduled_time_blocks)

    state = Map.replace(state, :schedule, new_schedule)
    {:reply, :ok, state}
  end

  def handle_call({:schedule_asset, asset_id, datetime}, _from, state) do
    # a more developed approach would have there be an entire asset id validation
    # mechanism put in place, along with probably date/time validation.
    # but this is the backend implementation and validation more appropriately
    # lives in the liveview.

    asset =
      state.assets
      |> Enum.filter(fn asset -> asset.id == asset_id end)
      |> hd()

    # need to know how many half hour time blocks past the floor to block off

    time_blocks = calculate_time_blocks(asset, datetime)

    # check each time block against the schedule to see if there are conflicts
    # if there's any value other than :ok, there's a conflict.

    conflicts =
      time_blocks
      |> Enum.map(fn x -> Map.get(state.schedule, x, :ok) end)
      |> Enum.uniq()

    case conflicts do
      [:ok] ->
        # no conflicts. add each time block to the state.

        new_schedule_blocks =
          time_blocks
          |> Enum.map(fn x -> {x, asset} end)
          |> Map.new()

        new_schedule = Map.merge(state.schedule, new_schedule_blocks)
        state = Map.replace(state, :schedule, new_schedule)
        {:reply, :ok, state}

      _ ->
        # some sort of conflict. what it is isn't relevant.
        {:reply, {:error, :time_conflict}, state}
    end
  end

  def handle_call(:get_schedule, _from, %{schedule: schedule} = state) do
    {:reply, schedule, state}
  end

  @spec calculate_time_blocks(__MODULE__.t(), DateTime.t()) :: list(DateTime.t())
  defp calculate_time_blocks(asset, datetime) do
    asset_time_blocks = Kernel.ceil(asset.duration / 1800)
    Logger.debug("#{asset_time_blocks} half hour blocks")

    time_blocks =
      Range.new(0, asset_time_blocks - 1)
      |> Enum.to_list()
      |> Enum.map(fn x ->
        DateTime.add(datetime, x * 1800, :second)
      end)

    time_blocks
  end

  @spec fetch_assets :: list(__MODULE__.t())
  def fetch_assets() do
    url = "https://test-bumpers.s3.amazonaws.com/an/int/assets.json"

    opts = [decode_json: [keys: :atoms]]
    {:ok, %Req.Response{status: 200, headers: _headers, body: body}} = Req.get(url, opts)

    # structs strongly help in enforcing data specifications

    Enum.map(body, fn x -> to_struct(x) end)
  end

  @spec to_struct(map) :: __MODULE__.t()
  def to_struct(data) do
    {:ok, upload_date, _offset} = DateTime.from_iso8601(data.uploadDate)

    data = %{
      description: data.description,
      duration: data.duration,
      id: data.id,
      image_url: data.image,
      title: data.title,
      upload_date: upload_date
    }

    Kernel.struct!(__MODULE__, data)
  end
end
