# Debugging

```elixir


# find pids for processes
Process.whereis PriceStreamer
Process.whereis Pipeline
Process.whereis Harjus.Supervisor

# find process info
Process.info(Process.whereis Pipeline)


Process.info Process.whereis Elixir.Harjus



```
