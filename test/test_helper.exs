# start all dependecies without starting the application
for app <- Application.spec(:harjus, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(MarketData.Exchange.TestMock, for: MarketData.Exchange)
Application.put_env(:harjus, :market_data_exchange, MarketData.Exchange.TestMock)

Mox.defmock(Balance.Exchange.TestMock, for: Balance.Exchange)
Application.put_env(:harjus, :balance_exchange, Balance.Exchange.TestMock)

Mox.defmock(TradeClient.Exchange.TestMock, for: TradeClient.Exchange)
Application.put_env(:harjus, :trade_client_exchange, TradeClient.Exchange.TestMock)

Mox.defmock(Trader.Balance.TestMock, for: Trader.Balance)
Application.put_env(:harjus, :balance, Trader.Balance.TestMock)

Mox.defmock(PriceStreamer.Exchange.TestMock, for: PriceStreamer.Exchange)
Application.put_env(:harjus, :price_streamer_exchange, PriceStreamer.Exchange.TestMock)

Application.put_env(:harjus, :path_to_port, "./build/harjus-port")

ExUnit.start()
