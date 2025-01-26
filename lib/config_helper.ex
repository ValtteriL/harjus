defmodule ConfigHelper do
  @moduledoc "Functions for reading config values in correct type"
  @type config_type :: :str | :int | :bool | :decimal | :list | :atom | :module

  @doc """
  Get value from environment variable, converting it to the given type if needed.

  If no default value is given, or `:no_default` is given as the default, an error is raised if the variable is not
  set.
  """
  @spec get_env(String.t(), :no_default | any(), config_type()) :: any()
  def get_env(var, default \\ :no_default, type \\ :str)

  def get_env(var, :no_default, type) do
    System.fetch_env!(var)
    |> get_with_type(type)
  end

  def get_env(var, default, type) do
    case System.fetch_env(var) do
      {:ok, val} -> get_with_type(val, type)
      :error -> default
    end
  end

  @spec get_with_type(String.t(), config_type()) :: any()
  defp get_with_type(val, type)

  defp get_with_type(val, :str), do: val
  defp get_with_type(val, :atom), do: String.to_atom(val)
  defp get_with_type(val, :int), do: String.to_integer(val)
  defp get_with_type("true", :bool), do: true
  defp get_with_type("false", :bool), do: false
  defp get_with_type(val, :decimal), do: Decimal.new(val)
  defp get_with_type(val, :list), do: String.split(val, ",")
  defp get_with_type(val, :module), do: Code.ensure_loaded!(String.to_existing_atom(val))
  defp get_with_type(val, type), do: raise("Cannot convert to #{inspect(type)}: #{inspect(val)}")
end
