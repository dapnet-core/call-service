defmodule Call.Dispatcher do
  use GenServer

  def dispatch(call) do
    GenServer.call(__MODULE__, {:dispatch, call})
  end

  def start_link do
    GenServer.start_link(__MODULE__, {}, [name: __MODULE__])
  end

  def init(_opts) do
    {:ok, nil}
  end

  def handle_call({:dispatch, call}, _from, state) do
    recipients = Map.get(call, "recipients", %{})

    subscribers = Map.get(recipients, "subscribers", [])
    |> Enum.map(fn subscriber -> get_subscriber(subscriber) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.into(%{})

    subscribers = Map.get(recipients, "subscriber_groups", [])
    |> Enum.map(fn group -> group_subscribers(group) end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Map.merge(subscribers)

    distribution = Map.get(call, "distribution", %{})

    transmitters = Map.get(distribution, "transmitters", [])
    |> Enum.map(fn transmitter -> get_transmitter(transmitter) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.into(%{})

    transmitters = Map.get(distribution, "transmitter_groups", [])
    |> Enum.map(fn group -> group_transmitters(group) end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Map.merge(transmitters)

    Enum.each(transmitters, fn {_, transmitter} ->
      Enum.each(subscribers, fn {_, subscriber} ->
        pagers = Map.get(subscriber, "pagers")
        Enum.each(pagers, fn pager ->
          if Map.get(pager, "enabled") do
            send_call(call, transmitter, pager)
          end
        end)
      end)
    end)

    {:reply, :ok, state}
  end

  def send_call(call, transmitter, pager) do
    transmitter_id = Map.get(transmitter, "_id")

    data = Poison.encode!(%{
      "id" => Map.get(call, "id"),
      "protocol" => "pocsag",
      "priority" => Map.get(call, "priority"),
      "expires_on" => Map.get(call, "expires_on"),
      "origin" => Map.get(call, "origin"),
      "message" => %{
        "ric" => Map.get(pager, "ric"),
        "function" => Map.get(pager, "function"),
        "type" => "alphanum",
        "speed" => 1200,
        "data" => Map.get(call, "data")
      }
    })

    Call.RabbitMQ.publish_call(transmitter_id, data)
  end
  def get_subscriber(id) do
    get_object("subscribers", id)
  end

  def get_transmitter(id) do
    get_object("transmitters", id)
  end

  def get_object(database, id) do
    result = DapnetService.CouchDB.db(database)
    |> CouchDB.Database.get(id)

    case result do
      {:ok, response} ->
        response
        |> Poison.decode!
        |> (&(%{id => &1})).()
      _ ->
        nil
    end
  end

  def group_subscribers(group) do
    group_members("subscribers", group)
  end

  def group_transmitters(group) do
    group_members("transmitters", group)
  end

  def group_members(database, group) do
    group = String.split(group, ".")
    startkey = Poison.encode!(group)
    endkey = group ++ [%{}] |> Poison.encode!
    options = %{
      "reduce" => false,
      "startkey" => startkey,
      "endkey" => endkey,
      "include_docs" => true
    }

    result = DapnetService.CouchDB.db(database)
    |> CouchDB.Database.view(database, "byGroup", options)

    case result do
      {:ok, response} ->
        response
        |> Poison.decode!
        |> Map.get("rows")
        |> Enum.map(fn row -> {Map.get(row, "id"), Map.get(row, "doc")} end)
        |> Enum.into(%{})
      _ ->
        %{}
    end
  end
end
