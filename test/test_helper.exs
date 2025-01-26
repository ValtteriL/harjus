# start all dependecies without starting the application
for app <- Application.spec(:harjus, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(MarketData.Exchange.TestMock, for: MarketData.Exchange)
Application.put_env(:harjus, :market_data_exchange, MarketData.Exchange.TestMock)

ExUnit.start()
