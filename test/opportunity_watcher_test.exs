defmodule OpportunityWatcherTest do
  use ExUnit.Case, async: true
  doctest OpportunityWatcher

  setup do
    # TODO: add trading paths?
    # TODO: pass pid where to send opportunities here?
    {:ok, pid} = OpportunityWatcher.start_link([])
    %{pid: pid}
  end

  test "symbol update emits positive opportunities", %{pid: pid} do
    # TODO
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 10000.0, 1.0})
  end

  test "symbol update does not emit negative opportunities", %{pid: pid} do
    # TODO
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 10000.0, 1.0})
  end

  test "no opportunities emitted if uninitialized", %{pid: pid} do
    # TODO
    OpportunityWatcher.update_symbol(pid, {"BTCUSDT", 10000.0, 1.0})
  end
end
