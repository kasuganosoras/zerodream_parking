-- You can implement your custom API here

-- Get player job name
-- Args: (number) player
-- Return: string
function GetPlayerJob(player)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        return xPlayer.job.name
    end

    -- For Standalone
    return 'player'
end

-- Get player nickname
-- Args: (number) player
-- Return: string
function GetPlayerNickname(player)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        return xPlayer.name
        -- or character name
        -- return string.format("%s %s", xPlayer.get('firstname'), xPlayer.get('lastname')
    end

    -- For Standalone
    return GetPlayerName(player)
end

-- Get player money
-- Args: (number) player
-- Return: number
function GetPlayerMoney(player)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        return xPlayer.getMoney()
    end

    -- For Standalone
    return 999999999
end

-- Remove player money
-- Args: (number) player, (number) amount
function RemovePlayerMoney(player, amount)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        xPlayer.removeMoney(amount)
        return
    end

    -- For Standalone
    -- Do nothing
end

-- Check if player have parking card
-- Args: (number) player
-- Return: boolean
function IsPlayerHaveParkingCard(player)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        return xPlayer.getInventoryItem(Config.parkingCard).count > 0
    end

    -- For Standalone
    return false
end

-- Get player identifier
-- Args: (number) player
-- Return: string
function GetIdentifierById(player)
    -- For ESX
    if Config.framework == 'esx' then
        local xPlayer = _g.ESX.GetPlayerFromId(player)
        return xPlayer.identifier
    end

    -- For Standalone
    local identifiers = GetPlayerIdentifiers(player)
    for _, v in ipairs(identifiers) do
        if string.find(v, 'license:') then
            return v
        end
    end
    return nil
end

-- Check if player is in whitelist
-- Args: (string) parking, (number) player
-- Return: boolean
function IsWhiteListPlayer(parking, player)
    local identifier  = GetIdentifierById(player)
    local ip          = GetPlayerEndpoint(player)
    local job         = GetPlayerJob(player)
    local parkingData = parking == 'global' and Config.globalParking or (Config.parking[parking] or { whitelist = {} })
    for k, v in pairs(parkingData.whitelist) do
        if v == string.format('identifier.%s', identifier) or v == string.format('ip.%s', ip) or v == string.format('job.%s', job) then
            return true
        end
    end
    return false
end

-- Check is blacklist car
-- Args: (string) parking, (number) model
-- Return: boolean
function IsBlackListCar(parking, model)
    local parkingData = parking == 'global' and Config.globalParking or (Config.parking[parking] or { blacklist = {} })
    for k, v in pairs(parkingData.blacklist) do
        if GetHashKey(v) == model then
            return true
        end
    end
    return false
end

-- Check is allow vehicle class
-- Args: (string) parking, (number) vehicleClass
-- Return: boolean
function IsAllowType(parking, vehicleClass)
    local parkingData = parking == 'global' and Config.globalParking or (Config.parking[parking] or { allowTypes = {} })
    for k, v in pairs(parkingData.allowTypes) do
        if v == -1 or v == vehicleClass then
            return true
        end
    end
    return false
end

-- Check is vehicle owned by player
-- Args: (number) player, (string) plate
-- Return: boolean
function IsOwnedVehicle(player, plate)
    -- For ESX
    if Config.framework == 'esx' then
        local result = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
            ['@owner'] = GetIdentifierById(player),
            ['@plate'] = plate
        })
        return type(result) == 'table' and result[1] ~= nil
    end

    -- For Standalone
    return true
end

-- Send notification to player
-- Args: (number) player, (string) message
function SendNotification(player, message)
    -- For ESX
    if Config.framework == 'esx' then
        TriggerClientEvent('esx:showNotification', player, message)
        return
    end

    -- For Standalone
    TriggerClientEvent('chat:addMessage', player, {
        color     = { 255, 255, 255},
        multiline = true,
        args      = { message }
    })
end
