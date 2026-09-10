--[[
    Brandstof laden/opslaan via SQL (owned_vehicles.fuel)
    Vereist: sql/install.sql + oxmysql of mysql-async
]]

local function normalizePlate(plate)
    if type(plate) ~= 'string' then
        return ''
    end
    return (plate:gsub('^%s+', ''):gsub('%s+$', ''):upper())
end

local function clampFuel(value)
    local n = tonumber(value) or 100.0
    if n < 0.0 then return 0.0 end
    if n > 100.0 then return 100.0 end
    return n + 0.0
end

local function dbScalar(query, params, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:scalar(query, params, function(result)
            cb(result)
        end)
        return true
    end

    if MySQL and MySQL.Async and MySQL.Async.fetchScalar then
        MySQL.Async.fetchScalar(query, params, cb)
        return true
    end

    return false
end

local function dbExecute(query, params)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params)
        return true
    end

    if MySQL and MySQL.Async and MySQL.Async.execute then
        MySQL.Async.execute(query, params)
        return true
    end

    return false
end

RegisterNetEvent('mallorca-speedometer:server:getFuel', function(plate)
    local src = source
    if not Config.Fuel or not Config.Fuel.UseDatabase then
        TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, 100.0)
        return
    end

    plate = normalizePlate(plate)
    if plate == '' then
        TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, 100.0)
        return
    end

    local ok = dbScalar(
        'SELECT `fuel` FROM `owned_vehicles` WHERE UPPER(TRIM(`plate`)) = ? LIMIT 1',
        { plate },
        function(result)
            local fuel = 100.0
            if result ~= nil then
                fuel = clampFuel(result)
            end
            TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, fuel)
        end
    )

    if not ok then
        print('^1[mallorca-speedometer]^7 Geen oxmysql/mysql-async. Brandstof komt niet uit SQL.')
        TriggerClientEvent('mallorca-speedometer:client:setFuel', src, plate, 100.0)
    end
end)

RegisterNetEvent('mallorca-speedometer:server:saveFuel', function(plate, fuel)
    if not Config.Fuel or not Config.Fuel.UseDatabase then
        return
    end

    plate = normalizePlate(plate)
    fuel = clampFuel(fuel)
    if plate == '' then
        return
    end

    local ok = dbExecute(
        'UPDATE `owned_vehicles` SET `fuel` = ? WHERE UPPER(TRIM(`plate`)) = ?',
        { fuel, plate }
    )

    if not ok then
        print('^1[mallorca-speedometer]^7 Kon brandstof niet opslaan (geen database-connector).')
    end
end)
