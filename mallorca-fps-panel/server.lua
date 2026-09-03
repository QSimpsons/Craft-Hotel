CreateThread(function()
    while true do
        local maxClients = GetConvarInt('sv_maxclients', Config.MaxPlayers)
        TriggerClientEvent('mallorca-fps:players', -1, #GetPlayers(), maxClients)
        Wait(2000)
    end
end)
