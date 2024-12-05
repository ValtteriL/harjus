defmodule OpportunityWatcherTest do
  use ExUnit.Case, async: true
  doctest OpportunityWatcher

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "generates correct trading paths" do
    assert 1 == 2
  end

end
