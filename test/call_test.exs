defmodule CallTest do
  use ExUnit.Case
  doctest Call

  test "greets the world" do
    assert Call.hello() == :world
  end
end
