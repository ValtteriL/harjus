defmodule KirnuTest do
  use ExUnit.Case
  doctest Kirnu

  test "greets the world" do
    assert Kirnu.hello() == :world
  end
end
