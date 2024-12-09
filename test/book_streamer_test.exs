defmodule OpportunityWatcherTest do
  use ExUnit.Case, async: true
  doctest OpportunityWatcher

  setup do
    {:ok, pid} = BookStreamer.start_link(self()) # TODO
    %{pid: pid}
  end

  test "reponds to ping", %{pid: pid} do
    assert false
  end

  test "subscribes to correct symbols" do
    assert false
  end

  test "forwards book ticker updates" do
    assert false
  end
end
