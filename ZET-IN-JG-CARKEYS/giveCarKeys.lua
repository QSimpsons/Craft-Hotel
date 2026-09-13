--[[
    ZET DIT BESTAND IN JE BESTAANDE jg-carkeys RESOURCE.

    1. Kopieer dit bestand naar:
       resources/jg-carkeys/giveCarKeys.lua
       of:
       resources/jg-carkeys/client/giveCarKeys.lua

    2. Open resources/jg-carkeys/fxmanifest.lua
       Voeg bij client_scripts deze regel toe:

       'giveCarKeys.lua',
       of (als het in de client-map staat):
       'client/giveCarKeys.lua',

    3. In de server console:
       ensure jg-carkeys
       ensure jg-anwb

    Dit maakt de ontbrekende export:
      exports['jg-carkeys']:giveCarKeys(plate, props)
]]

local ownedPlates = {}

local function Trim(value)
    if value == nil then
        return ''
    end
    return (tostring(value):gsub('^%s*(.-)%s*$', '%1'))
end

local function GiveCarKeys(plate, props, vehicle)
    plate = Trim(plate)
    if plate == '' and type(props) == 'table' then
        plate = Trim(props.plate)
    end
    if plate == '' and vehicle and vehicle ~= 0 then
        plate = Trim(GetVehicleNumberPlateText(vehicle))
    end
    if plate == '' then
        return false
    end

    ownedPlates[plate] = true

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
    end

    if GetResourceState('jg-givekey') == 'started' then
        pcall(function()
            exports['jg-givekey']:giveCarKeys(plate, props, vehicle)
        end)
    end

    TriggerEvent('jg-carkeys:client:giveKeys', plate, props, vehicle)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerEvent('cd_garage:AddKeys', plate)
    return true
end

exports('giveCarKeys', GiveCarKeys)
exports('GiveCarKeys', GiveCarKeys)
exports('GiveKeys', GiveCarKeys)
exports('GiveKey', GiveCarKeys)
