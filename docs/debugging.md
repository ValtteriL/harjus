# Debugging

```elixir


# find pids for processes
Process.whereis PortfolioManager
Process.whereis OpportunityWatcher
Process.whereis Kirnu.Supervisor

# find process info
Process.info(Process.whereis OpportunityWatcher)






```
