defmodule Call.Router do
  use Plug.Router

  plug DapnetService.Plug.Api
  plug DapnetService.Plug.BasicAuth
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison

  plug :match
  plug :dispatch

  post "/calls" do
    schema = Call.Schema.call_schema
    call = conn.body_params
    user = conn.assigns[:login]["user"]["_id"]

    case ExJsonSchema.Validator.validate(schema, call) do
      :ok ->
        call = call
        |> Map.put("id", uuid())
        |> Map.put("origin", origin())
        |> Map.put("created_on", Timex.now())
        |> Map.put("created_by", user)

        Call.Dispatch.dispatch call
        Call.Database.store call

        json_call = Poison.encode!(call)
        Call.RabbitMQ.publish_call(json_call)

        send_resp(conn, 200, json_call)
      {:error, errors} ->
        errors = Enum.map(errors, fn {msg, value} -> "#{msg} (#{value})" end)
        send_resp(conn, 400, Poison.encode!(%{"errors" => errors}))
    end
  end

  get "/calls" do
    IO.inspect conn

    case Call.Database.list() do
      nil ->
        send_resp(conn, 404, '{"error": "Not found"}')
      result ->
        send_resp(conn, 200, Poison.encode!(result))
    end
  end

  get "/calls/:id" do
    case Call.Database.read(id) do
      nil ->
        send_resp(conn, 404, '{"error": "Not found"}')
      result ->
        send_resp(conn, 200, Poison.encode!(result))
    end
  end

  get "/calls/status" do
    send_resp(conn, 200, '{"status": "ok"}')
  end

  defp uuid() do
    UUID.uuid1()
  end

  defp origin() do
    System.get_env("NODE_NAME")
  end
end
