defmodule ConfigHelperTest do
  @moduledoc "Tests for ConfigHelper"
  use ExUnit.Case
  doctest ConfigHelper

  test "parses int" do
    env_name = "test_env"
    System.put_env(env_name, "42")
    assert ConfigHelper.get_env(env_name, :no_default, :int) == 42
  end

  test "parses atom" do
    env_name = "test_env"
    System.put_env(env_name, "this_should_become_an_atom")
    assert ConfigHelper.get_env(env_name, :no_default, :atom) == :this_should_become_an_atom
  end

  test "parses module" do
    env_name = "test_env"
    System.put_env(env_name, "Kernel")
    assert ConfigHelper.get_env(env_name, :no_default, :module) == Kernel
  end

  test "parses decimal" do
    env_name = "test_env"
    dec = "42.42"
    System.put_env(env_name, dec)
    assert ConfigHelper.get_env(env_name, :no_default, :decimal) == Decimal.new(dec)
  end

  test "parses bool" do
    env_name = "test_env"
    System.put_env(env_name, "true")
    assert ConfigHelper.get_env(env_name, :no_default, :bool) == true

    env_name = "test_env"
    System.put_env(env_name, "false")
    assert ConfigHelper.get_env(env_name, :no_default, :bool) == false
  end

  test "parses list" do
    env_name = "test_env"
    System.put_env(env_name, "a,b,c")
    assert ConfigHelper.get_env(env_name, :no_default, :list) == ["a", "b", "c"]
  end

  test "parses string" do
    env_name = "test_env"
    System.put_env(env_name, "hello")
    assert ConfigHelper.get_env(env_name, :no_default, :str) == "hello"
  end

  test "default value works" do
    env_name = "test_env_some_default"
    assert ConfigHelper.get_env(env_name, "default", :str) == "default"
  end
end
