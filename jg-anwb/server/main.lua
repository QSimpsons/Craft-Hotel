ESX = exports["es_extended"]:getSharedObject()

TriggerEvent('esx_phone:registerNumber', 'mechanic', 'mechanic', true, true)
TriggerEvent('esx_society:registerSociety', 'mechanic', 'mechanic', 'society_mechanic', 'society_mechanic', 'society_mechanic', {type = 'public'})


RegisterServerEvent('jg-anwb:server:getGear')
AddEventHandler('jg-anwb:server:getGear', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == 'mechanic' then
        xPlayer.addInventoryItem('radio', 1)
        xPlayer.addInventoryItem('WEAPON_FIREEXTINGUISHER', 1)
    else 
        DropPlayer(source, "Verboden exploites te gebruiken")
    end
end)

RegisterServerEvent('jg-anwb:server:repair:vehicle')
AddEventHandler('jg-anwb:server:repair:vehicle', function()
    local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem('repairkit', 1)
end)

RegisterServerEvent('jg-anwb:server:wash:vehicle')
AddEventHandler('jg-anwb:server:wash:vehicle', function()
    local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem('washand', 1)
end)

RegisterNetEvent('jg-anwb:server:toggleDuty', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then
        return
    end

    local jobName = xPlayer.job.name
    local grade = xPlayer.job.grade or 0

    if jobName == 'mechanic' then
        xPlayer.setJob('offmechanic', grade)
        TriggerClientEvent('esx:showNotification', src, 'Je bent uitgeklokt.')
    elseif jobName == 'offmechanic' then
        xPlayer.setJob('mechanic', grade)
        TriggerClientEvent('esx:showNotification', src, 'Je bent ingeklokt.')
    end
end)