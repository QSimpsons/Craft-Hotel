local IsDead = false
local IsAnimated = false

local function setPlayerNeeds(hunger, thirst)
    TriggerEvent('esx_status:set', 'hunger', hunger)
    TriggerEvent('esx_status:set', 'thirst', thirst)
end

local function requestAnimDict(dict, cb)
    if xLib and xLib.streaming and xLib.streaming.requestAnimDict then
        xLib.streaming.requestAnimDict(dict, cb)
        return
    end

    if ESX.Streaming and ESX.Streaming.RequestAnimDict then
        ESX.Streaming.RequestAnimDict(dict, cb)
        return
    end

    RequestAnimDict(dict)
    CreateThread(function()
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
        if cb then
            cb(dict)
        end
    end)
end

AddEventHandler('esx_basicneeds:resetStatus', function()
    setPlayerNeeds(500000, 500000)
end)

RegisterNetEvent('esx_basicneeds:healPlayer', function()
    setPlayerNeeds(1000000, 1000000)

    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
end)

AddEventHandler('esx:onPlayerDeath', function()
    IsDead = true
end)

AddEventHandler('esx:onPlayerSpawn', function()
    if IsDead then
        setPlayerNeeds(500000, 500000)
    end

    IsDead = false
end)

AddEventHandler('esx_status:loaded', function()
    TriggerEvent('esx_status:registerStatus', 'hunger', 1000000, '#CFAD0F', function()
        return Config.Visible
    end, function(status)
        status.remove(100)
    end)

    TriggerEvent('esx_status:registerStatus', 'thirst', 1000000, '#0C98F1', function()
        return Config.Visible
    end, function(status)
        status.remove(75)
    end)
end)

AddEventHandler('esx_status:onTick', function(statuses)
    local playerPed = PlayerPedId()
    local prevHealth = GetEntityHealth(playerPed)
    local newHealth = prevHealth

    for _, status in pairs(statuses) do
        if status.percent == 0 and (status.name == 'hunger' or status.name == 'thirst') then
            newHealth = newHealth - ((prevHealth <= 150) and 5 or 1)
        end
    end

    if newHealth ~= prevHealth then
        SetEntityHealth(playerPed, newHealth)
    end
end)

AddEventHandler('esx_basicneeds:isEating', function(callback)
    callback(IsAnimated)
end)

local function handleAnimation(itemType, propName, anim, pos, rot)
    if IsAnimated then
        return
    end

    IsAnimated = true
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(playerPed))
    local prop = CreateObject(joaat(propName), x, y, z + 0.2, true, true, true)
    local boneIndex = GetPedBoneIndex(playerPed, 18905)

    pos = pos or vector3(0.12, 0.028, 0.001)
    rot = rot or vector3(10.0, 175.0, 0.0)
    anim = anim or {
        dict = itemType == 'food' and 'mp_player_inteat@burger' or 'mp_player_intdrink',
        name = itemType == 'food' and 'mp_player_int_eat_burger_fp' or 'loop_bottle',
        settings = itemType == 'food' and { 8.0, -8, -1, 49, 0, 0, 0, 0 } or { 1.0, -1.0, 2000, 0, 1, true, true, true }
    }

    AttachEntityToEntity(prop, playerPed, boneIndex, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)

    CreateThread(function()
        requestAnimDict(anim.dict, function()
            TaskPlayAnim(playerPed, anim.dict, anim.name, table.unpack(anim.settings))
            RemoveAnimDict(anim.dict)

            Wait(3000)
            IsAnimated = false
            ClearPedSecondaryTask(playerPed)
            DeleteObject(prop)
        end)
    end)
end

RegisterNetEvent('esx_basicneeds:onUse', function(itemType, propName, anim, pos, rot)
    propName = propName or (itemType == 'food' and 'prop_cs_burger_01' or 'prop_ld_flow_bottle')
    handleAnimation(itemType, propName, anim, pos, rot)
end)

local function warnDeprecated(eventName, itemType, propName)
    local invokingResource = GetInvokingResource() or 'unknown'
    print(('[^3WARNING^7] ^5%s^7 used ^5%s^7, which is deprecated on ESX 1.15. Use esx_basicneeds:onUse instead.'):format(invokingResource, eventName))
    TriggerEvent('esx_basicneeds:onUse', itemType, propName)
end

RegisterNetEvent('esx_basicneeds:onEat', function(propName)
    warnDeprecated('esx_basicneeds:onEat', 'food', propName or 'prop_cs_burger_01')
end)

RegisterNetEvent('esx_basicneeds:onDrink', function(propName)
    warnDeprecated('esx_basicneeds:onDrink', 'drink', propName or 'prop_ld_flow_bottle')
end)
