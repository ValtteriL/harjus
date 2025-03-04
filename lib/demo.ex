defmodule Demo do
  @moduledoc """
  demo module
  """

  def run(nworkers) do
    child =
      spawn(fn ->
        Stream.resource(
          fn -> :ok end,
          fn _ ->
            receive do
              {:msg, msg} ->
                IO.puts("# received #{inspect(msg)}")
                {[msg], nil}

              # discard other messages (e.g. task references)
              _ ->
                {[], nil}
            end
          end,
          fn _ -> :ok end
        )
        |> Stream.each(fn x ->
          IO.puts("## before #{inspect(x)}")
          x
        end)
        |> Task.async_stream(
          fn x ->
            Process.sleep(:rand.uniform(1000))
            IO.puts("### at #{inspect(x)}")
            x
          end,
          ordered: false,
          max_concurrency: nworkers
        )
        |> Stream.each(fn x ->
          IO.puts("#### after #{inspect(x)}")
          x
        end)
        |> Stream.run()
      end)

    1..10
    |> Enum.each(fn x -> send(child, {:msg, x}) end)
  end
end
