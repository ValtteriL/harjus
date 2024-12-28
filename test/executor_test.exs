defmodule ExecutorTest do
  use ExUnit.Case

  test "start_link/1 starts the GenServer" do
    {:ok, pid} = Executor.start_link([])
    assert Process.alive?(pid)
  end

  test "handle_cast/2 handles :opportunity messages" do
    {:ok, pid} = Executor.start_link([])
    GenServer.cast(pid, {:opportunity, %{profit: 10}})
    assert %{opportunities: [%{profit: 10}]} = :sys.get_state(pid)
  end

  test "send_opportunity/2 sends opportunities to the executor" do
    {:ok, pid} = Executor.start_link([])
    Executor.send_opportunity(pid, %{profit: 10})
    assert %{opportunities: [%{profit: 10}]} = :sys.get_state(pid)
  end

  test "send_trade_update/2 sends trade updates to the executor" do
    {:ok, pid} = Executor.start_link([])
    Executor.send_trade_update(pid, %{status: :filled})
    assert_receive {:noreply, _}
  end
end
