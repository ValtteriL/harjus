# start all dependecies without starting the application
for app <- Application.spec(:harjus, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(MarketData.Exchange.TestMock, for: MarketData.Exchange)
Application.put_env(:harjus, :market_data_exchange, MarketData.Exchange.TestMock)

Mox.defmock(Balance.Exchange.TestMock, for: Balance.Exchange)
Application.put_env(:harjus, :balance_exchange, Balance.Exchange.TestMock)

Mox.defmock(Trader.TradeClient.Exchange.TestMock, for: Trader.TradeClient.Exchange)
Application.put_env(:harjus, :trade_client_exchange, Trader.TradeClient.Exchange.TestMock)

Mox.defmock(Trader.Balance.TestMock, for: Trader.Balance)
Application.put_env(:harjus, :balance, Trader.Balance.TestMock)

Mox.defmock(PortfolioManager.BalanceMock, for: PortfolioManager.Balance)
Application.put_env(:harjus, :balance, PortfolioManager.BalanceMock)

ExUnit.start()
