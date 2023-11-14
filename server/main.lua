_g = {
    serverCallbacks = {},
}

if Config.framework == 'esx' then
    _g.ESX = nil
    while _g.ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) _g.ESX = obj end)
    end
end

if Config.framework == 'esx1.9' then
    _g.ESX = exports["es_extended"]:getSharedObject()
end

if Config.framework == 'qbcore' then
    _g.QBCore = exports['qb-core']:GetCoreObject()
end

if Config.impound.command then
    if Config.framework ~= 'standalone' then
        RegisterCommand(Config.impound.command, function(source, args, rawCommand)
            local _source = source
            if _source == 0 then
                local plate = table.concat(args, ' ')
                if plate then
                    local result = ImpoundVehicle(_source, GetCleanPlateNumber(plate))
                    print(result)
                else
                    print(_U('IMPOUND_INVALID_ARGS'))
                end
            else
                local job = GetPlayerJob(_source)
                if IsInTable(Config.impound.job, job) then
                    local plate = table.concat(args, ' ')
                    if plate then
                        ImpoundVehicle(_source, GetCleanPlateNumber(plate))
                    else
                        SendNotification(_source, _U('IMPOUND_INVALID_ARGS'))
                    end
                else
                    SendNotification(_source, _U('NOT_ALLOWED_PERMISSION'))
                end
            end
        end, false)
    else
        RegisterCommand(Config.impound.command, function(source, args, rawCommand)
            local _source = source
            local plate   = GetCleanPlateNumber(table.concat(args, ' '))
            local result  = plate ~= "" and ImpoundVehicle(_source, plate) or _U('IMPOUND_INVALID_ARGS')
            if _source == 0 then
                print(result)
            else
                SendNotification(_source, result)
            end
        end, true)
    end
end

function RegisterServerCallback(name, cb)
    if not cb then
        error("RegisterServerCallback: missing callback")
    end
    if not name then
        error("RegisterServerCallback: missing name")
    end
    if _g.serverCallbacks[name] ~= nil then
        error("RegisterServerCallback: there is already a callback with name '" .. name .. "'")
    end
    DebugPrint('Registering server callback: ' .. name)
    _g.serverCallbacks[name] = cb
end

function ImpoundVehicle(player, plate)
    local _plate = GetCleanPlateNumber(plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM parking_vehicles WHERE plate = @plate', {
        ['@plate'] = _plate
    })
    if type(result) == 'table' and result[1] ~= nil then
        if Config.framework == 'esx' then
            MySQL.Sync.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate', {
                ['@stored'] = '0',
                ['@plate']  = _plate
            })
        end
        if Config.framework == 'qbcore' then
            MySQL.Sync.execute('UPDATE player_vehicles SET state = @state WHERE plate = @plate', {
                ['@state'] = '0',
                ['@plate'] = _plate
            })
        end
        MySQL.Sync.execute('DELETE FROM parking_vehicles WHERE plate = @plate', {
            ['@plate'] = _plate
        })
        if player ~= 0 then
            OnVehicleImpounded(player, result[1].parking, result[1].plate)
        end
        TriggerClientEvent('zerodream_parking:removeParkingVehicle', -1, result[1].parking, result[1].plate)
        return SendNotification(player, _U('IMPOUND_SUCCESS'))
    else
        return SendNotification(player, _U('VEHICLE_NOT_FOUND'))
    end
end

RegisterServerCallback('zerodream_parking:impoundVehicle', function(source, cb, plate)
    local _source = source
    local job     = GetPlayerJob(_source)
    if IsInTable(Config.impound.job, job) then
        local _plate = GetCleanPlateNumber(plate)
        local result = ImpoundVehicle(_source, _plate)
        cb({
            success = true,
            message = _U('IMPOUND_SUCCESS'),
        })
    else
        cb({
            success = false,
            message = _U('NOT_ALLOWED_PERMISSION'),
        })
    end
end)

RegisterServerCallback('zerodream_parking:getPlayerData', function(source, cb)
    local _source = source
    if Config.framework == 'esx' or Config.framework == 'esx1.9' then
        local xPlayer = _g.ESX.GetPlayerFromId(_source)
        cb({ identifier = xPlayer.identifier })
        return
    end
    if Config.framework == 'qbcore' then
        local identifier = _g.QBCore.Functions.GetIdentifier(_source, 'license')
        cb({ identifier = identifier })
        return
    end
    cb({ identifier = GetIdentifierById(source) })
end)

RegisterNetEvent('QBCore:Server:UpdateObject', function()
	if source ~= '' then return false end
	_g.QBCore = exports['qb-core']:GetCoreObject()
end)

RegisterServerEvent('zerodream_parking:ready')
AddEventHandler('zerodream_parking:ready', function()
    local _source  = source
    local vehicles = {}
    DebugPrint(string.format("Player %s is ready", _source))
    local result   = MySQL.Sync.fetchAll('SELECT * FROM parking_vehicles', {})
    if type(result) == 'table' and result[1] ~= nil then
        DebugPrint(string.format("Sending data to %s", GetPlayerNickname(_source)))
        for k, v in pairs(result) do
            local posData = json.decode(v.position)
            if vehicles[v.parking] == nil then
                vehicles[v.parking] = {}
            end
            vehicles[v.parking][v.plate] = {
                plate    = v.plate,
                owner    = v.owner,
                name     = v.name,
                position = vec3(posData.x, posData.y, posData.z),
                rotation = vec3(posData.rx, posData.ry, posData.rz),
                props    = json.decode(v.properties),
                data     = json.decode(v.data),
                time     = tonumber(v.time),
                parking  = v.parking,
            }
        end
    end
    TriggerLatentClientEvent('zerodream_parking:syncParkingVehicles', _source, 1024000, os.time(), vehicles)
end)

RegisterServerEvent('zerodream_parking:syncDamage')
AddEventHandler('zerodream_parking:syncDamage', function(netId, damage)
    TriggerLatentClientEvent('zerodream_parking:syncDamage', -1, 1024000, netId, damage)
end)

RegisterServerCallback('zerodream_parking:findVehicle', function(source, cb, plate)
    local _source    = source
    local _plate     = GetCleanPlateNumber(plate)
    local identifier = GetIdentifierById(_source)
    DebugPrint("Searching for vehicle " .. _plate .. " for " .. identifier)
    local result = MySQL.Sync.fetchAll('SELECT * FROM parking_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = identifier,
        ['@plate'] = _plate
    })
    if type(result) == 'table' and result[1] ~= nil then
        local posData = json.decode(result[1].position)
        cb({
            success = true,
            message = _U('VEHICLE_FOUND'),
            data    = {
                x = posData.x,
                y = posData.y,
            }
        })
    else
        cb({
            success = false,
            message = _U('VEHICLE_NOT_FOUND'),
        })
    end
end)

RegisterServerCallback('zerodream_parking:saveVehicle', function(source, cb, payload)
    local _source = source
    local plate   = GetCleanPlateNumber(payload.plate)
    local checker = IsAllowedParking(_source, payload.parking, plate)
    if plate then
        local result  = MySQL.Sync.fetchAll('SELECT * FROM parking_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        })
        -- Check if already in parking
        if type(result) == 'table' and result[1] ~= nil then
            cb({
                success = false,
                message = _U('VEHICLE_ALREADY_PARKED'),
            })
        -- Check is allowed vehicle
        elseif not IsAllowType(payload.parking, payload.class) or IsBlackListCar(payload.parking, payload.model) then
            cb({
                success = false,
                message = _U('VEHICLE_NOT_ALLOWED'),
            })
        -- Check is owned vehicle
        elseif not Config.notOwnedCar and not IsOwnedVehicle(_source, plate) then
            cb({
                success = false,
                message = _U('VEHICLE_NOT_OWNED'),
            })
        -- Check is parking full
        elseif GetVehiclesInParking(payload.parking, true) >= GetMaxParkingVehicles(payload.parking) then
            cb({
                success = false,
                message = _U('ERROR_PARKING_FULL'),
            })
        elseif not checker.allowed then
            cb({
                success = false,
                message = checker.message,
            })
        -- Pass the test, storage to database
        else
            MySQL.Async.execute('INSERT INTO parking_vehicles (plate, owner, name, position, properties, data, time, parking) VALUES (@plate, @owner, @name, @position, @properties, @data, @time, @parking)', {
                ['@plate']      = plate,
                ['@owner']      = GetIdentifierById(_source),
                ['@name']       = GetPlayerNickname(_source),
                ['@properties'] = json.encode(payload.props),
                ['@data']       = json.encode(payload.data),
                ['@time']       = os.time(),
                ['@parking']    = payload.parking,
                ['@position']   = json.encode({
                    x  = payload.position.x,
                    y  = payload.position.y,
                    z  = payload.position.z,
                    rx = payload.rotation.x,
                    ry = payload.rotation.y,
                    rz = payload.rotation.z,
                }),
            }, function(rowsChanged)
                OnVehicleStored(_source, payload.parking, plate)
                cb({
                    success = true,
                    message = _U('VEHICLE_PARKED_SUCCESS'),
                })
                -- Notify all clients
                TriggerLatentClientEvent('zerodream_parking:addParkingVehicle', -1, 1024000, payload.parking, plate, {
                    plate    = plate,
                    owner    = GetIdentifierById(_source),
                    name     = GetPlayerNickname(_source),
                    position = payload.position,
                    rotation = payload.rotation,
                    props    = payload.props,
                    data     = payload.data,
                    time     = os.time(),
                    parking  = payload.parking,
                })
            end)
        end
    else
        cb({
            success = false,
            message = "INTERNAL_ERROR",
        })
    end
end)

RegisterServerCallback('zerodream_parking:driveOutVehicle', function(source, cb, plate)
    local _source    = source
    local identifier = GetIdentifierById(_source)
    local _plate     = GetCleanPlateNumber(plate)
    local result  = MySQL.Sync.fetchAll('SELECT * FROM parking_vehicles WHERE plate = @plate', {
        ['@plate'] = _plate
    })
    if type(result) == 'table' and result[1] ~= nil then
        if result[1].owner == identifier then
            local parkingCrd  = IsPlayerHaveParkingCard(_source)
            local parkingFee  = parkingCrd and 0 or GetParkingFee(result[1].parking, result[1].time)
            local playerMoney = GetPlayerMoney(_source)
            local checker     = IsAllowedDrive(_source, result[1].parking, result[1].plate)
            if checker.allowed then
                if Config.framework == 'standalone' or IsWhiteListPlayer(result[1].parking, _source) then
                    parkingFee = 0
                end
                if playerMoney >= parkingFee then
                    if parkingFee > 0 then
                        RemovePlayerMoney(_source, parkingFee)
                    end
                    MySQL.Async.execute('DELETE FROM parking_vehicles WHERE plate = @plate', {
                        ['@plate'] = _plate,
                    }, function(rowsChanged)
                        OnVehicleDrive(_source, result[1].parking, _plate)
                        cb({
                            success = true,
                            message = parkingFee > 0 and _UF('VEHICLE_PAID_SUCCESS', parkingFee) or _U('VEHICLE_TAKE_SUCCESS'),
                        })
                        -- Notify all clients
                        TriggerLatentClientEvent('zerodream_parking:removeParkingVehicle', -1, 1024000, result[1].parking, _plate)
                    end)
                else
                    cb({
                        success = false,
                        message = _UF('NOT_ENOUGH_MONEY', parkingFee),
                    })
                end
            else
                cb({
                    success = false,
                    message = checker.message,
                })
            end
        else
            cb({
                success = false,
                message = _U('VEHICLE_NOT_OWNED'),
            })
        end
    else
        cb({
            success = false,
            message = _U('VEHICLE_NOT_FOUND'),
        })
    end
end)

MySQL.ready(function()
    CheckDatabase()
end)
