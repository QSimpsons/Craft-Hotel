--[[
    Kopieer dit bestand naar je bestaande jg-carkeys resource (bijv. jg-carkeys/client/)
    en voeg het toe in fxmanifest.lua onder client_scripts.

    Dit registreert de ontbrekende export:

        exports['jg-carkeys']:giveCarKeys(plate, props)

    zodat JG jobs (jg-anwb, politie, etc.) niet crashen.
]]

local function ForwardToGiveKey(plate, props, vehicle)
    if GetResourceState('jg-givekey') == 'started' then
        exports['jg-givekey']:giveCarKeys(plate, props, vehicle)
        return
    end

    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerEvent('jg-carkeys:client:giveKeys', plate, props, vehicle)
end

exports('giveCarKeys', ForwardToGiveKey)
exports('GiveCarKeys', ForwardToGiveKey)
exports('GiveKeys', ForwardToGiveKey)
exports('GiveKey', ForwardToGiveKey)
