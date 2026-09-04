RegisterNetEvent('mallorca_fps:requestPing', function()
    local src = source
    local ping = GetPlayerPing(src)
    TriggerClientEvent('mallorca_fps:updatePing', src, ping)
end)
