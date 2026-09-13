local cachedSettings = {}
local SETTING_KEYS = Config.Settings

local function colName(btn)
    return (btn:gsub('-', '_'))
end

local function emptySettings()
    local t = {}
    for i = 1, #SETTING_KEYS do
        t[SETTING_KEYS[i]] = false
    end
    return t
end

local function normalizeSettings(data)
    local t = emptySettings()
    if type(data) ~= 'table' then return t end
    for i = 1, #SETTING_KEYS do
        local key = SETTING_KEYS[i]
        local v = data[key]
        t[key] = (v == true or v == 1 or v == '1')
    end
    return t
end

local function hasOx()
    return GetResourceState('oxmysql') == 'started'
end

local function hasMysqlAsync()
    return MySQL ~= nil and MySQL.Async ~= nil
end

local function dbSingle(query, params, cb)
    if hasOx() then
        if exports.oxmysql.single then
            exports.oxmysql:single(query, params, cb)
        else
            exports.oxmysql:query(query, params, function(rows)
                cb(rows and rows[1] or nil)
            end)
        end
        return true
    end
    if hasMysqlAsync() then
        MySQL.Async.fetchAll(query, params, function(rows)
            cb(rows and rows[1] or nil)
        end)
        return true
    end
    return false
end

local function dbExec(query, params, cb)
    if hasOx() then
        exports.oxmysql:execute(query, params, cb)
        return true
    end
    if hasMysqlAsync() then
        MySQL.Async.execute(query, params, cb or function() end)
        return true
    end
    return false
end

local function GetPlayerDBId(src)
    if Config.Identifier == 'esx' and GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                return xPlayer.identifier or (xPlayer.getIdentifier and xPlayer.getIdentifier())
            end
        end
    end

    local ids = GetPlayerIdentifiers(src)
    for i = 1, #ids do
        if ids[i]:sub(1, 8) == 'license:' then
            return ids[i]
        end
    end
    return ids[1]
end

local function EnsureTable()
    if not Config.UseDatabase then return end

    local sql = [[
        CREATE TABLE IF NOT EXISTS `mallorca_fps_settings` (
            `identifier` VARCHAR(72) NOT NULL,
            `btn_laag` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_boost` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_texturen` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_nogpu` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_grafics` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_vignette` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_zwartwit` TINYINT(1) NOT NULL DEFAULT 0,
            `btn_schaduwen` TINYINT(1) NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]

    if not dbExec(sql, {}) then
        print('^3[mallorca-fps]^7 Geen oxmysql/mysql-async — instellingen worden niet in SQL opgeslagen.')
    end
end

local function RowToSettings(row)
    local t = emptySettings()
    if not row then return t end
    for i = 1, #SETTING_KEYS do
        local key = SETTING_KEYS[i]
        local col = colName(key)
        local v = row[col]
        t[key] = (v == true or v == 1 or v == '1')
    end
    return t
end

local function SaveToDatabase(identifier, settings)
    if not Config.UseDatabase or not identifier then return end
    settings = normalizeSettings(settings)

    local cols, placeholders, updates, insertValues, updateValues = {}, {}, {}, {}, {}
    cols[#cols + 1] = '`identifier`'
    placeholders[#placeholders + 1] = '?'
    insertValues[#insertValues + 1] = identifier

    for i = 1, #SETTING_KEYS do
        local key = SETTING_KEYS[i]
        local col = '`' .. colName(key) .. '`'
        local bit = settings[key] and 1 or 0
        cols[#cols + 1] = col
        placeholders[#placeholders + 1] = '?'
        insertValues[#insertValues + 1] = bit
        updates[#updates + 1] = col .. ' = ?'
        updateValues[#updateValues + 1] = bit
    end

    local values = {}
    for i = 1, #insertValues do values[#values + 1] = insertValues[i] end
    for i = 1, #updateValues do values[#values + 1] = updateValues[i] end

    local query = ('INSERT INTO `mallorca_fps_settings` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s'):format(
        table.concat(cols, ', '),
        table.concat(placeholders, ', '),
        table.concat(updates, ', ')
    )

    dbExec(query, values)
end

local function LoadFromDatabase(identifier, cb)
    if not Config.UseDatabase or not identifier then
        cb(emptySettings())
        return
    end

    local ok = dbSingle(
        'SELECT * FROM `mallorca_fps_settings` WHERE `identifier` = ? LIMIT 1',
        { identifier },
        function(row)
            cb(RowToSettings(row))
        end
    )

    if not ok then
        cb(emptySettings())
    end
end

local function PushSettings(src)
    local identifier = GetPlayerDBId(src)
    if not identifier then
        TriggerClientEvent('mallorca_fps:loadSettings', src, emptySettings())
        return
    end

    if cachedSettings[src] then
        TriggerClientEvent('mallorca_fps:loadSettings', src, cachedSettings[src])
        return
    end

    LoadFromDatabase(identifier, function(settings)
        cachedSettings[src] = settings
        TriggerClientEvent('mallorca_fps:loadSettings', src, settings)
    end)
end

RegisterNetEvent('mallorca_fps:requestSettings', function()
    PushSettings(source)
end)

RegisterNetEvent('mallorca_fps:saveSettings', function(settings)
    local src = source
    local identifier = GetPlayerDBId(src)
    settings = normalizeSettings(settings)
    cachedSettings[src] = settings
    SaveToDatabase(identifier, settings)
end)

RegisterNetEvent('mallorca_fps:requestPing', function()
    local src = source
    TriggerClientEvent('mallorca_fps:updatePing', src, GetPlayerPing(src) or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local settings = cachedSettings[src]
    if settings then
        SaveToDatabase(GetPlayerDBId(src), settings)
        cachedSettings[src] = nil
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local src = tonumber(playerId) or playerId
    if type(src) ~= 'number' then return end
    cachedSettings[src] = nil
    PushSettings(src)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    EnsureTable()
    print('^2[mallorca-fps]^7 Gestart. SQL = ' .. tostring(Config.UseDatabase))
end)
