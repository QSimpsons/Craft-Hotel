local function ResourceStarted(name)
    return type(name) == 'string' and name ~= '' and GetResourceState(name) == 'started'
end

local function GiveCarKeys(src, plate, props, netId)
    src = tonumber(src)
    if not src or src <= 0 then
        return false
    end

    TriggerClientEvent('jg-givekey:client:giveCarKeys', src, plate, props, netId)
    return true
end

local function RemoveCarKeys(src, plate, props, netId)
    src = tonumber(src)
    if not src or src <= 0 then
        return false
    end

    TriggerClientEvent('jg-givekey:client:removeCarKeys', src, plate, props, netId)
    return true
end

exports('giveCarKeys', GiveCarKeys)
exports('GiveCarKeys', GiveCarKeys)
exports('GiveKeys', GiveCarKeys)
exports('GiveKey', GiveCarKeys)
exports('removeCarKeys', RemoveCarKeys)
exports('RemoveCarKeys', RemoveCarKeys)

RegisterNetEvent('jg-givekey:server:giveCarKeys', function(plate, props, netId)
    GiveCarKeys(source, plate, props, netId)
end)

RegisterNetEvent('jg-givekey:server:removeCarKeys', function(plate, props, netId)
    RemoveCarKeys(source, plate, props, netId)
end)

AddEventHandler('playerDropped', function()
    -- Client-side key cache is per-player and clears automatically on drop.
end)

-- Optional bridge: if jg-carkeys later starts with a different API, jobs remain stable.
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if ResourceStarted('jg-carkeys') then
        print('^3[jg-givekey]^7 jg-carkeys draait ook. Jobs kunnen giveCarKeys via jg-givekey blijven gebruiken.')
    end
end)
