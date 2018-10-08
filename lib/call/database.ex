defmodule Call.Database do
  use GenServer
  alias :mnesia, as: Mnesia

  def start_link do
    GenServer.start_link(__MODULE__, {}, [name: __MODULE__])
  end

  def init(_opts) do
    Mnesia.create_schema([node()])
    Mnesia.start()

    Mnesia.create_table(Calls, [
          attributes: [:created_on, :id, :data],
          type: :ordered_set,
          disc_copies: [Node.self()],
        ])

    Mnesia.add_table_index(Calls, :d)
    {:ok, nil}
  end

  def store(call) do
    id = Map.get(call, "id")
    created_on = Map.get(call, "created_on")

    transaction = fn ->
      Mnesia.write({Calls, created_on, id, call})
    end

    Mnesia.transaction(transaction)
  end

  def read(id) do
    transaction = fn ->
      Mnesia.read({Calls, id})
    end

    case Mnesia.transaction(transaction) do
      {:atomic, [{Calls, _created_on, _id, data}]} ->
        data
      other ->
        nil
    end
  end

  def list do
    transaction = fn ->
      Mnesia.select(Calls, [{{Calls, :"$1", :"$2", :"$3"}, [], [:"$3"]}])
    end

    case Mnesia.transaction(transaction) do
      {:atomic, list} ->
        list
      other ->
        nil
    end
  end
end
