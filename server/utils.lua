RegisterServerEvent("zerodream_parking:triggerServerCallback")
AddEventHandler("zerodream_parking:triggerServerCallback", function(name, requestId, ...)
    local _source = source
    local cb = _g.serverCallbacks[name]
    if not cb then
        print(_g.serverCallbacks[name])
        error("TriggerServerCallback: callback not found with name '" .. name .. "'")
    end
    cb(_source, function(...)
        TriggerClientEvent("zerodream_parking:triggerServerCallback", _source, requestId, ...)
    end, ...)
end)

-- Debug print
function DebugPrint(...)
    if Config.debug then
        print(...)
    end
end

-- Check if using item limit
function IsUsingItemLimit()
    local result = MySQL.Sync.fetchAll('DESCRIBE `items` `limit`')
    return type(result) == 'table' and result[1] ~= nil
end

-- Check database
function CheckDatabase()
    -- Check if parking_vehicles table exists
    local result = MySQL.Sync.fetchAll('SHOW TABLES LIKE @table', {
        ['@table'] = 'parking_vehicles'
    })
    if type(result) ~= 'table' or result[1] == nil then
        print("^1Initializing database...^0")
        MySQL.Sync.execute([[CREATE TABLE `parking_vehicles`  (
            `plate` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
            `owner` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
            `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
            `position` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
            `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
            `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
            `time` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
            `parking` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
            PRIMARY KEY (`plate`) USING BTREE
        ) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;]])
        print("^2Database initialized^0")
    elseif Config.globalParking.enable then
        MySQL.Sync.execute('UPDATE `parking_vehicles` SET `parking` = @parking', {
            ['@parking'] = 'global'
        })
    end

    -- Check if parking card exists
    if Config.framework == 'esx' or Config.framework == 'esx1.9' then
        local result = MySQL.Sync.fetchAll('SELECT * FROM `items` WHERE `name` = @name', {
            ['@name'] = Config.parkingCard
        })
        if type(result) ~= 'table' or result[1] == nil then
            if IsUsingItemLimit() then
                MySQL.Sync.execute('INSERT INTO `items` (`name`, `label`, `limit`) VALUES (@name, @label, @limit)', {
                    ['@name']  = Config.parkingCard,
                    ['@label'] = 'Parking Card',
                    ['@limit'] = 1,
                })
            else
                MySQL.Sync.execute('INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight)', {
                    ['@name']   = Config.parkingCard,
                    ['@label']  = 'Parking Card',
                    ['@weight'] = 0,
                })
            end
            -- Reboot server to take effect
            print("^1Parking Card has been added to the database, you should restart your server to take effect!^0")
        end
    end

    if Config.framework == 'qbcore' then
        exports['qb-core']:AddItem(Config.parkingCard, {
            name        = Config.parkingCard,
            label       = 'Parking Card',
            weight      = 10,
            type        = 'item',
            image       = 'parking_card.png',
            unique      = true,
            useable     = false,
            shouldClose = false,
            combinable  = nil,
            description = 'Allow you park your vehicle for free',
        })
    end
end

-- Get parking fee
function GetParkingFee(parking, beginTime)
    local parkingData = parking == 'global' and Config.globalParking or Config.parking[parking]
    local parkingDays = (os.time() - beginTime) / 86400
    return parkingData and math.ceil(parkingDays * parkingData.parkingFee) or 0
end

-- Get parking vehicles
function GetVehiclesInParking(parking, getNum)
    local sql = getNum and 'SELECT `plate` FROM parking_vehicles WHERE parking = @parking' or 'SELECT * FROM parking_vehicles WHERE parking = @parking'
    local result = MySQL.Sync.fetchAll(sql, {
        ['@parking'] = parking
    })
    if type(result) == 'table' and result[1] ~= nil then
        return getNum and #result or result
    else
        return getNum and 0 or {}
    end
end

-- Get max parking vehicles
function GetMaxParkingVehicles(parking)
    local parkingData = parking == 'global' and Config.globalParking or Config.parking[parking]
    return parkingData and parkingData.maxCars or 0
end

function IsInTable(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function TimestampToDate(timestamp)
    local date = os.date('*t', timestamp)
    return {
        y = date.year,
        m = date.month,
        d = date.day,
        h = date.hour,
        i = date.min,
        s = date.sec
    }
end