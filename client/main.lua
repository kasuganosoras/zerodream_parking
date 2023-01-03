_g = {
    clientCallbacks   = {},
    currentCallbackId = 0,
}

function InitCommands()
    RegisterCommand(Config.commands.parkingVehicle, function(source, args, rawCommand)
        ParkingVehicle()
    end, false)
    
    if Config.commands.engineControl then
        RegisterCommand(Config.commands.engineControl, function(source, args, rawCommand)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then
                local engineOn = GetIsVehicleEngineRunning(vehicle)
                SetVehicleEngineOn(vehicle, not engineOn, true, true)
            end
        end, false)
    end

    if Config.commands.findVehicle then
        RegisterCommand(Config.commands.findVehicle, function(source, args, rawCommand)
            local plate = args[1]
            if plate then
                FindVehicle(plate)
            else
                SendNotification(_U('FIND_VEHICLE_INVALID'))
            end
        end, false)
    end
    
    if Config.keyBinding.engineControl then
        RegisterKeyMapping(Config.commands.engineControl, _U('KEY_ENGINE_CONTROL'), 'keyboard', Config.keyBinding.engineControl)
    end
    
    if Config.keyBinding.parkingVehicle then
        RegisterKeyMapping(Config.commands.parkingVehicle, _U('KEY_PARKING_VEHICLES'), 'keyboard', Config.keyBinding.parkingVehicle)
    end
end

function CreateParkingCar(payload)
    if not payload.props then return false end
    local model = (type(payload.props.model) == 'number' and payload.props.model or GetHashKey(payload.props.model))
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    local vehicle = CreateVehicle(model, payload.position, 0.0, false, false)
    SetEntityRotation(vehicle, payload.rotation, 2, true)
    SetVehicleOnGroundProperly(vehicle)
    if payload.owner ~= _g.identifier then
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        SetVehicleUndriveable(vehicle, true)
    end
    if payload.data then
        SetVehicleExtraData(vehicle, payload.data)
    end
    SetVehicleProperties(vehicle, payload.props)
    SetVehicleEngineOn(vehicle, false, false, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(vehicle, true)
    return vehicle
end

function ProcessParking()
    local playerPed = GetPlayerPed(-1)
    local playerCrd = GetEntityCoords(playerPed)
    _g.isOnVehicle  = IsPedInAnyVehicle(playerPed, false)
    _g.driveVehicle = _g.isOnVehicle  and GetVehiclePedIsIn(playerPed, false) or nil
    _g.isEngineOn   = _g.isOnVehicle  and GetIsVehicleEngineRunning(_g.driveVehicle) or false
    _g.isParkingCar = _g.isOnVehicle  and IsParkingVehicle(_g.driveVehicle) or false
    _g.parkingCar   = _g.isParkingCar and GetCurrentParkingCar() or nil
    if not Config.globalParking.enable then
        local findParking = false
        for id, parking in pairs(Config.parking) do
            local distance = #(playerCrd - parking.pos)
            if distance <= parking.size then
                _g.currentParking = id
                findParking = true
                break
            end
        end
        if not findParking then
            _g.currentParking = nil
            if not Config.globalParking.enable then
                Wait(1000)
            end
        end
    end
    playerPed, playerCrd = nil, nil, nil, nil
end

function ProcessCarLoading()
    _g.closeVehicle = nil
    if _g.parkingVehicles then
        local parkingName = Config.globalParking.enable and 'global' or _g.currentParking
        if parkingName then
            local playerPed = GetPlayerPed(-1)
            local playerCrd = GetEntityCoords(playerPed)
            local vehicles  = _g.parkingVehicles[parkingName] or {}
            for plate, vehicle in pairs(vehicles) do
                local distance = #(playerCrd - vehicle.position)
                if (Config.globalParking.enable and distance <= Config.globalParking.distance) or _g.currentParking then
                    if not vehicle.entity or not DoesEntityExist(vehicle.entity) then
                        vehicle.entity = CreateParkingCar(vehicle)
                        DebugPrint("Creating vehicle for " .. vehicle.plate .. " result " .. tostring(vehicle.entity))
                        Wait(200)
                    end
                else
                    if vehicle.entity then
                        DeleteEntity(vehicle.entity)
                        vehicle.entity = nil
                    end
                end
                if distance < 3 then
                    _g.closeVehicle = vehicle
                end
            end
        else
            for parkingName, vehicles in pairs(_g.parkingVehicles) do
                for plate, vehicle in pairs(vehicles) do
                    if vehicle.entity then
                        DebugPrint("Deleting vehicle for " .. vehicle.plate)
                        DeleteEntity(vehicle.entity)
                        vehicle.entity = nil
                    end
                end
            end
        end
        parkingName, playerPed, playerCrd, vehicles, distance = nil, nil, nil, nil, nil
    end
end

function ParkingAction(parkingName, vehicle)
    local playerPed = GetPlayerPed(-1)
    local playerCrd = GetEntityCoords(playerPed)
    if not IsParkingVehicle(vehicle) then
        if not Config.stopEngine or not GetIsVehicleEngineRunning(vehicle) then
            if GetEntitySpeed(vehicle) < 1 then
                if IsPedInAnyVehicle(playerPed, false) then
                    TaskLeaveAnyVehicle(playerPed, 0, 0)
                end
                Citizen.Wait(1800)
                local payload = {
                    model     = GetEntityModel(vehicle),
                    class     = GetVehicleClass(vehicle),
                    plate     = GetVehicleNumberPlateText(vehicle),
                    props     = GetVehicleProperties(vehicle),
                    position  = GetEntityCoords(vehicle),
                    rotation  = GetEntityRotation(vehicle, 2),
                    data      = GetVehicleExtraData(vehicle),
                    parking   = parkingName,
                }
                TriggerServerCallback('zerodream_parking:saveVehicle', function(result)
                    _g.requestPending = false
                    SendNotification(result.message)
                    if result.success then
                        FreezeEntityPosition(vehicle, true)
                        SetEntityCompletelyDisableCollision(vehicle, true, false)
                        NetworkFadeOutEntity(vehicle, false, false)
                        Wait(500)
                        DeleteEntity(vehicle)
                    end
                end, payload)
            else
                _g.requestPending = false
                SendNotification(_U('VEHICLE_IS_MOVING'))
            end
        else
            _g.requestPending = false
            SendNotification(_U('STOP_ENGINE_FIRST'))
        end
    else
        TriggerServerCallback('zerodream_parking:driveOutVehicle', function(result)
            _g.requestPending = false
            if result.success then
                while not NetworkGetEntityIsNetworked(vehicle) do
                    NetworkRegisterEntityAsNetworked(vehicle)
                    Citizen.Wait(100)
                end
                FreezeEntityPosition(vehicle, false)
                SetEntityInvincible(vehicle, false)
                SetVehicleDoorsLocked(vehicle, 0)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
            end
            SendNotification(result.message)
        end, GetVehicleNumberPlateText(vehicle))
    end
end

function ParkingVehicle()
    if _g.requestPending then
        return
    end
    _g.requestPending = true
    local playerPed = GetPlayerPed(-1)
    local playerCrd = GetEntityCoords(playerPed)
    if Config.globalParking.enable or _g.currentParking then
        local parkingName = Config.globalParking.enable and 'global' or _g.currentParking
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                ParkingAction(parkingName, vehicle)
            else
                SendNotification(_U('NOT_IN_DRIVER_SEAT'))
            end
        else
            local closeVeh = GetClosestVehicle(playerCrd.x, playerCrd.y, playerCrd.z, 3.0, 0, 127)
            if closeVeh and DoesEntityExist(closeVeh) then
                _g.ignoreRemove = closeVeh
                PlayKeyAnim(closeVeh)
                QuickVehicleHorn(closeVeh, 2)
                ParkingAction(parkingName, closeVeh)
            end
        end
    end
end

function FindVehicle(plate)
    TriggerServerCallback('zerodream_parking:findVehicle', function(result)
        if result.success then
            SetNewWaypoint(result.data.x, result.data.y)
        end
        SendNotification(result.message)
    end, plate)
end

RegisterNetEvent('zerodream_parking:syncParkingVehicles')
AddEventHandler('zerodream_parking:syncParkingVehicles', function(serverTime, vehicles)
    DebugPrint('Received parking vehicles list')
    _g.reciveTime = GetGameTimer()
    _g.serverTime = serverTime
    _g.parkingVehicles = vehicles
end)

RegisterNetEvent('zerodream_parking:addParkingVehicle')
AddEventHandler('zerodream_parking:addParkingVehicle', function(parking, plate, data)
    if not _g.parkingVehicles[parking] then
        _g.parkingVehicles[parking] = {}
    end
    _g.parkingVehicles[parking][plate] = data
end)

RegisterNetEvent('zerodream_parking:removeParkingVehicle')
AddEventHandler('zerodream_parking:removeParkingVehicle', function(parking, plate)
    if _g.parkingVehicles[parking] then
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
        if not DoesEntityExist(vehicle) or GetVehicleNumberPlateText(vehicle) ~= plate then
            if _g.parkingVehicles[parking][plate] and _g.parkingVehicles[parking][plate].entity then
                if not _g.ignoreRemove or _g.ignoreRemove ~= _g.parkingVehicles[parking][plate].entity then
                    DeleteEntity(_g.parkingVehicles[parking][plate].entity)
                    _g.ignoreRemove = nil
                end
            end
        end
        _g.parkingVehicles[parking][plate] = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if _g.parkingVehicles then
            for _, vehicles in pairs(_g.parkingVehicles) do
                for _, vehicle in pairs(vehicles) do
                    if vehicle.entity then
                        DeleteEntity(vehicle.entity)
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()

    -- Wait for 1 second
    Wait(1000)
    DebugPrint(GetKeyMapping(Config.commands.engineControl))

    -- If using ESX framework, wait for ESX to be ready
    if Config.framework == 'esx' then
        DebugPrint('Waiting for ESX load...')
        _g.ESX = nil
        Citizen.CreateThread(function()
            while _g.ESX == nil do
                TriggerEvent('esx:getSharedObject', function(obj) _g.ESX = obj end)
                Citizen.Wait(0)
            end
        end)
    end

    -- Wait for the game to be ready
    DebugPrint('Waiting for game load...')
    while not IsGameReady() do
        Wait(0)
    end

    if Config.framework == 'esx' then
        DebugPrint('Loading player data...')

        AddEventHandler('esx:onPlayerSpawn', function()
            TriggerServerCallback('zerodream_parking:getPlayerData', function(data)
                _g.identifier = data.identifier
            end)
        end)
    else
    -- Load player data
    DebugPrint('Loading player data...')
    TriggerServerCallback('zerodream_parking:getPlayerData', function(data)
        _g.identifier = data.identifier
    end)
    end



    -- Wait for data load
    while not _g.identifier do
        Wait(0)
    end

    -- Initialize commands
    DebugPrint('Initializing commands...')
    InitCommands()

    -- Notify server that client is ready
    DebugPrint('Client is ready!')
    TriggerServerEvent('zerodream_parking:ready')

    -- Enter main loop
    while true do
        Wait(500)
        ProcessParking()
        ProcessCarLoading()
    end
end)

Citizen.CreateThread(function()
    local parkingKey  = GetKeyMapping(Config.commands.parkingVehicle)
    local engineKey   = GetKeyMapping(Config.commands.engineControl)
    while true do
        Wait(0)
        if not Config.globalParking.enable then
            if _g.currentParking then
                if _g.isOnVehicle then
                    if not _g.isParkingCar then
                        local parking = Config.parking[_g.currentParking]
                        if parking.notify then
                            if Config.stopEngine and _g.isEngineOn then
                                DisplayHelpText(_UF('PRESS_TO_STOP_ENGINE', engineKey))
                            else
                                DisplayHelpText(_UF('PRESS_TO_SAVE_VEHICLE', parkingKey))
                            end
                        end
                    else
                        local parkFees = GetParkingFeeByCar(_g.parkingCar)
                        if parkFees > 0 then
                            DisplayHelpText(_UF('PRESS_TO_PAY_PARK_FEE', parkingKey, parkFees))
                        else
                            DisplayHelpText(_UF('PRESS_TO_TAKE_VEHICLE', parkingKey))
                        end
                    end
                end
            else
                Wait(500)
            end
        elseif _g.isOnVehicle and _g.isParkingCar then
            local parkFees = GetParkingFeeByCar(_g.parkingCar)
            if parkFees > 0 then
                DisplayHelpText(_UF('PRESS_TO_PAY_PARK_FEE', parkingKey, parkFees))
            else
                DisplayHelpText(_UF('PRESS_TO_TAKE_VEHICLE', parkingKey))
            end
        elseif not _g.isOnVehicle and _g.closeVehicle then
            local position  = _g.closeVehicle.position
            local vehNames  = GetLabelText(GetDisplayNameFromVehicleModel(_g.closeVehicle.props.model))
            local ownerName = _g.closeVehicle.name
            local parkFees  = GetParkingFeeByCar(_g.closeVehicle)
            AdvancedDrawText3D(position, _UF('VEHICLE_INFO', vehNames, ownerName, _g.closeVehicle.plate, parkFees))
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        collectgarbage("collect")
        Wait(60000)
    end
end)