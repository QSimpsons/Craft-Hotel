local function getXPlayer(src)
    if ESX.Player then
        local player = ESX.Player(src)
        if player then
            return player
        end
    end

    return ESX.GetPlayerFromId(src)
end

local function getIdentifier(xPlayer)
    if xPlayer.getIdentifier then
        return xPlayer.getIdentifier()
    end

    return xPlayer.identifier
end

local function getSource(xPlayer)
    return xPlayer.source or xPlayer.src
end

local function setPlayerStatus(xPlayer, encoded)
    local status = encoded and json.decode(encoded) or {}
    xPlayer.set('status', status)
    TriggerClientEvent('esx_status:load', getSource(xPlayer), status)
end

local function loadPlayerStatus(xPlayer)
    if not xPlayer then
        return
    end

    local identifier = getIdentifier(xPlayer)
    if not identifier then
        return
    end

    local result = MySQL.scalar.await('SELECT `status` FROM `users` WHERE `identifier` = ? LIMIT 1', { identifier })
    setPlayerStatus(xPlayer, result)
end

AddEventHandler('esx:playerLoaded', function(_, xPlayer)
    loadPlayerStatus(xPlayer)
end)

AddEventHandler('esx:playerDropped', function(src)
    local xPlayer = getXPlayer(src)
    if not xPlayer then
        return
    end

    local status = xPlayer.get('status') or {}
    local identifier = getIdentifier(xPlayer)
    if identifier then
        MySQL.update('UPDATE users SET status = ? WHERE identifier = ?', { json.encode(status), identifier })
    end
end)

AddEventHandler('esx_status:getStatus', function(src, statusName, cb)
    local xPlayer = getXPlayer(src)
    if not xPlayer then
        return
    end

    local status = xPlayer.get('status') or {}
    for i = 1, #status do
        if status[i].name == statusName then
            return cb(status[i])
        end
    end
end)

RegisterNetEvent('esx_status:update', function(status)
    local xPlayer = getXPlayer(source)
    if not xPlayer then
        return
    end

    xPlayer.set('status', status)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        while GetResourceState('es_extended') ~= 'started' do
            Wait(100)
        end

        Wait(1000)

        local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
        for _, xPlayer in pairs(players) do
            loadPlayerStatus(xPlayer)
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)

        local parameters = {}
        local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}

        for _, xPlayer in pairs(players) do
            local status = xPlayer.get and xPlayer.get('status')
            local identifier = getIdentifier(xPlayer)
            if status and next(status) and identifier then
                parameters[#parameters + 1] = { json.encode(status), identifier }
            end
        end

        if #parameters > 0 then
            MySQL.prepare('UPDATE users SET status = ? WHERE identifier = ?', parameters)
        end
    end
end)
