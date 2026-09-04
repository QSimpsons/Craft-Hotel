local hudVisible = true
local radarVisible = true
local pauseHidden = false
local cachedStatus = {}

local EMPTY_JOB = {
    name = 'unemployed',
    label = 'Werkloos',
    grade_label = ''
}

local function registerNetEvent(name, handler)
    if ESX.SecureNetEvent then
        ESX.SecureNetEvent(name, handler)
        return
    end

    RegisterNetEvent(name)
    AddEventHandler(name, handler)
end

local function getStatus()
    if GetResourceState('esx_status') ~= 'started' then
        return cachedStatus
    end

    local ok, status = pcall(function()
        return exports.esx_status:GetStatusData()
    end)

    if ok and type(status) == 'table' and #status > 0 then
        cachedStatus = status
        return status
    end

    return cachedStatus
end

local function getAccounts()
    local accounts = {
        money = { money = 0 },
        bank = { money = 0 },
        black_money = { money = 0 }
    }

    local playerAccounts = ESX.PlayerData and ESX.PlayerData.accounts
    if type(playerAccounts) ~= 'table' then
        return accounts
    end

    for i = 1, #playerAccounts do
        local account = playerAccounts[i]
        if account and account.name then
            accounts[account.name] = { money = account.money or 0 }
        end
    end

    return accounts
end

function updateHud()
    if not hudVisible or pauseHidden or not ESX.PlayerLoaded then
        SendNUIMessage({
            action = 'updateHud',
            data = { hud = false }
        })
        return
    end

    local playerData = ESX.PlayerData or {}

    SendNUIMessage({
        action = 'updateHud',
        data = {
            job = playerData.job or EMPTY_JOB,
            job2 = playerData.job2,
            status = getStatus(),
            accounts = getAccounts(),
            idnum = GetPlayerServerId(PlayerId()),
            hud = true
        }
    })
end

exports('updateHud', updateHud)

function OnPlayerData(key)
    if key == 'job' or key == 'job2' or key == 'accounts' then
        updateHud()
    end
end

CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(200)
    end

    updateHud()
end)

registerNetEvent('esx:playerLoaded', function(xPlayer)
    if xPlayer then
        ESX.PlayerData = xPlayer
    end

    CreateThread(function()
        while not ESX.PlayerLoaded do
            Wait(100)
        end

        Wait(500)
        updateHud()
    end)
end)

registerNetEvent('esx:onPlayerLogout', function()
    SendNUIMessage({
        action = 'updateHud',
        data = { hud = false }
    })
end)

registerNetEvent('esx:setJob', function(job)
    if ESX.PlayerData then
        ESX.PlayerData.job = job
    end
    updateHud()
end)

-- Dual-job is not part of vanilla ESX 1.15.0; keep this for servers that add job2.
RegisterNetEvent('esx:setJob2', function(job)
    if ESX.PlayerData then
        ESX.PlayerData.job2 = job
    end
    updateHud()
end)

registerNetEvent('esx:setAccountMoney', function(account)
    if not account or not ESX.PlayerData or type(ESX.PlayerData.accounts) ~= 'table' then
        updateHud()
        return
    end

    for i = 1, #ESX.PlayerData.accounts do
        if ESX.PlayerData.accounts[i].name == account.name then
            ESX.PlayerData.accounts[i].money = account.money
            break
        end
    end

    updateHud()
end)

AddEventHandler('esx_status:onTick', function(data)
    if type(data) == 'table' then
        cachedStatus = data
    end
    updateHud()
end)

AddEventHandler('esx_status:loaded', function()
    Wait(0)
    updateHud()
end)

if Config.HideInPauseMenu then
    CreateThread(function()
        while true do
            Wait(300)

            local paused = IsPauseMenuActive()
            if paused and not pauseHidden then
                pauseHidden = true
                updateHud()
            elseif not paused and pauseHidden then
                pauseHidden = false
                updateHud()
            end
        end
    end)
end

CreateThread(function()
    while true do
        Wait(Config.RefreshMs or 1000)
        if hudVisible and ESX.PlayerLoaded and not pauseHidden then
            updateHud()
        end
    end
end)

local function toggleHud()
    hudVisible = not hudVisible
    updateHud()
end

local function toggleRadar()
    radarVisible = not radarVisible
    DisplayRadar(radarVisible)
end

RegisterCommand('hud', toggleHud, false)
RegisterCommand('radar', toggleRadar, false)
RegisterCommand('minimap', toggleRadar, false)
