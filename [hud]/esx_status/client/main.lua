local OriginalStatus, Status, isPaused = {}, {}, false
local loadToken = 0

function GetStatusData(minimal)
    local status = {}

    for i = 1, #Status do
        if minimal then
            status[#status + 1] = {
                name = Status[i].name,
                val = Status[i].val,
                percent = (Status[i].val / Config.StatusMax) * 100
            }
        else
            status[#status + 1] = {
                name = Status[i].name,
                val = Status[i].val,
                color = Status[i].color,
                visible = Status[i].visible(Status[i]),
                percent = (Status[i].val / Config.StatusMax) * 100
            }
        end
    end

    return status
end

exports('GetStatusData', GetStatusData)

AddEventHandler('esx_status:registerStatus', function(name, default, color, visible, tickCallback)
    local status = CreateStatus(name, default, color, visible, tickCallback)

    for i = 1, #OriginalStatus do
        if status.name == OriginalStatus[i].name then
            status.set(OriginalStatus[i].val)
        end
    end

    Status[#Status + 1] = status
end)

AddEventHandler('esx_status:unregisterStatus', function(name)
    for i = 1, #Status do
        if Status[i].name == name then
            table.remove(Status, i)
            break
        end
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Status = {}
    OriginalStatus = {}

    if Config.Display then
        SendNUIMessage({
            update = true,
            status = Status
        })
    end
end)

RegisterNetEvent('esx_status:load', function(status)
    while not ESX.PlayerLoaded do
        Wait(50)
    end

    loadToken = loadToken + 1
    local token = loadToken

    OriginalStatus = status or {}
    TriggerEvent('esx_status:loaded')

    if Config.Display then
        TriggerEvent('esx_status:setDisplay', 0.5)
    end

    CreateThread(function()
        local data = {}
        while ESX.PlayerLoaded and token == loadToken do
            for i = 1, #Status do
                Status[i].onTick()
                data[#data + 1] = {
                    name = Status[i].name,
                    val = Status[i].val,
                    percent = (Status[i].val / Config.StatusMax) * 100
                }
            end

            if Config.Display then
                for i = 1, #data do
                    data[i].color = Status[i].color
                    data[i].visible = Status[i].visible(Status[i])
                end

                SendNUIMessage({
                    update = true,
                    status = data
                })
            end

            TriggerEvent('esx_status:onTick', data)
            table.wipe(data)
            Wait(Config.TickTime)
        end
    end)
end)

RegisterNetEvent('esx_status:set', function(name, val)
    for i = 1, #Status do
        if Status[i].name == name then
            Status[i].set(val)
            break
        end
    end

    if Config.Display then
        SendNUIMessage({
            update = true,
            status = GetStatusData()
        })
    end
end)

RegisterNetEvent('esx_status:add', function(name, val)
    for i = 1, #Status do
        if Status[i].name == name then
            Status[i].add(val)
            break
        end
    end

    if Config.Display then
        SendNUIMessage({
            update = true,
            status = GetStatusData()
        })
    end
end)

RegisterNetEvent('esx_status:remove', function(name, val)
    for i = 1, #Status do
        if Status[i].name == name then
            Status[i].remove(val)
            break
        end
    end

    if Config.Display then
        SendNUIMessage({
            update = true,
            status = GetStatusData()
        })
    end
end)

AddEventHandler('esx_status:getStatus', function(name, cb)
    for i = 1, #Status do
        if Status[i].name == name then
            cb(Status[i])
            return
        end
    end
end)

AddEventHandler('esx_status:getAllStatus', function(cb)
    cb(Status)
end)

AddEventHandler('esx_status:setDisplay', function(val)
    SendNUIMessage({
        setDisplay = true,
        display = val
    })
end)

if Config.Display then
    AddEventHandler('esx:pauseMenuActive', function(state)
        if state then
            isPaused = true
            TriggerEvent('esx_status:setDisplay', 0.0)
            return
        end

        isPaused = false
        TriggerEvent('esx_status:setDisplay', 0.5)
    end)

    AddEventHandler('esx:loadingScreenOff', function()
        if not isPaused then
            TriggerEvent('esx_status:setDisplay', 0.3)
        end
    end)
end

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if ESX.PlayerLoaded then
            TriggerServerEvent('esx_status:update', GetStatusData(true))
        end
    end
end)
