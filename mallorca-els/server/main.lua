local function clampStage(value)
    local stage = math.floor(tonumber(value) or 0)
    if stage < 0 then
        return 0
    end
    if stage > 3 then
        return 3
    end
    return stage
end

RegisterNetEvent('mallorca-els:update', function(netId, payload)
    local src = source
    netId = tonumber(netId)
    if not netId or type(payload) ~= 'table' then
        return
    end

    local data = {
        stage = clampStage(payload.stage),
        scene = payload.scene == true,
        model = tostring(payload.model or '')
    }

    if data.model ~= 'fmltow' and data.model ~= 'dlbrickade' then
        return
    end

    TriggerClientEvent('mallorca-els:apply', -1, src, netId, data)
end)
