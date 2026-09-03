local visible = true
local playerCount = 0
local maxPlayers = Config.MaxPlayers
local voiceLabel = 'Normaal'

local function pushState()
    if not visible then
        return
    end

    local fps = math.floor((1.0 / GetFrameTime()) + 0.5)
    local player = PlayerId()

    SendNUIMessage({
        action = 'update',
        fps = fps,
        ping = GetPlayerPing(player),
        id = GetPlayerServerId(player),
        players = playerCount,
        maxPlayers = maxPlayers,
        voice = voiceLabel,
        discord = Config.Discord,
        serverName = Config.ServerName,
        tagline = Config.Tagline
    })
end

local function setVisible(state)
    visible = state
    SendNUIMessage({
        action = 'toggle',
        show = visible
    })
    if visible then
        pushState()
    end
end

RegisterCommand(Config.Command, function()
    setVisible(not visible)
end, false)

RegisterKeyMapping(Config.Command, 'Mallorca FPS panel aan/uit', 'keyboard', Config.ToggleKey)

RegisterNetEvent('mallorca-fps:players', function(count, max)
    playerCount = count or 0
    maxPlayers = max or Config.MaxPlayers
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    if mode == 1 then
        voiceLabel = 'Fluisteren'
    elseif mode == 3 then
        voiceLabel = 'Schreeuwen'
    else
        voiceLabel = 'Normaal'
    end
end)

AddEventHandler('SaltyChat_VoiceRangeChanged', function(_, _, index)
    if index == 0 then
        voiceLabel = 'Fluisteren'
    elseif index == 2 then
        voiceLabel = 'Schreeuwen'
    else
        voiceLabel = 'Normaal'
    end
end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({
        action = 'init',
        discord = Config.Discord,
        serverName = Config.ServerName,
        tagline = Config.Tagline
    })
    setVisible(true)

    while true do
        if visible then
            pushState()
        end
        Wait(Config.UpdateInterval)
    end
end)
