defmodule Call.Schema do
  def call_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => [
        "data",
        "priority",
        "recipients",
        "distribution"
      ],
      "properties" => %{
        "priority" => %{
          "type" => "integer",
          "minimum" => 1,
          "maximum" => 5
        },
        "expires_on" => %{"type" => "string"},
        "data" => %{"type" => "string"},
        "recipients" => %{
          "type" => "object",
          "properties" => %{
            "subscribers" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            },
            "subscriber_groups" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            }
          }
        },
        "distribution" => %{
          "type" => "object",
          "properties" => %{
            "transmitters" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            },
            "transmitter_groups" => %{
              "type" => "array",
              "items" => %{"type" => "string"}
            }
          }
        }
      }
    }
    |> ExJsonSchema.Schema.resolve()
  end
end
