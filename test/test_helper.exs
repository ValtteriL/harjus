# start all dependecies without starting the application
for app <- Application.spec(:harjus, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
