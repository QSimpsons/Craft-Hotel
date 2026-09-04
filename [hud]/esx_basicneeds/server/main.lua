local function handleItemUsage(itemName, itemConfig, src)
    local xPlayer = ESX.Player and ESX.Player(src) or ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end

    if itemConfig.remove then
        xPlayer.removeInventoryItem(itemName, 1)
    end

    local statusType, notificationMessage
    if itemConfig.type == 'food' then
        statusType = 'hunger'
        notificationMessage = TranslateCap('used_food', ESX.GetItemLabel(itemName) or itemName)
    elseif itemConfig.type == 'drink' then
        statusType = 'thirst'
        notificationMessage = TranslateCap('used_drink', ESX.GetItemLabel(itemName) or itemName)
    else
        print(('^1[ERROR]^0 Item "%s" has an invalid type defined.'):format(itemName))
        return
    end

    TriggerClientEvent('esx_status:add', src, statusType, itemConfig.status)
    TriggerClientEvent('esx_basicneeds:onUse', src, itemConfig.type, itemConfig.prop, itemConfig.anim, itemConfig.pos, itemConfig.rot)

    if xPlayer.showNotification then
        xPlayer.showNotification(notificationMessage)
    else
        TriggerClientEvent('esx:showNotification', src, notificationMessage)
    end
end

CreateThread(function()
    for itemName, itemConfig in pairs(Config.Items) do
        ESX.RegisterUsableItem(itemName, function(src)
            handleItemUsage(itemName, itemConfig, src)
        end)
    end
end)

ESX.RegisterCommand('heal', 'admin', function(xPlayer, args, showError)
    if not args.playerId then
        return showError('Player ID is required')
    end

    args.playerId.triggerEvent('esx_basicneeds:healPlayer')
    args.playerId.showNotification(TranslateCap('got_healed'))
end, true, {
    help = 'Heal a player, or yourself - restores thirst, hunger and health.',
    validate = true,
    arguments = {
        { name = 'playerId', help = 'The player ID', type = 'player' }
    }
})

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' or type(eventData.id) ~= 'number' then
        return
    end

    TriggerClientEvent('esx_basicneeds:healPlayer', eventData.id)
end)
