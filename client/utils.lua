function TriggerServerCallback(name, cb, ...)
    if not name then
        error("TriggerServerCallback: missing name")
    end

    if not cb then
        error("TriggerServerCallback: missing callback")
    end

    local id = _g.currentCallbackId + 1
    _g.currentCallbackId = id
    _g.clientCallbacks[id] = cb
    TriggerServerEvent("zerodream_parking:triggerServerCallback", name, id, ...)
end

-- Debug print
function DebugPrint(...)
    if Config.debug then
        print(...)
    end
end

-- Check is game ready
function IsGameReady()
    return NetworkIsSessionStarted() and DoesEntityExist(GetPlayerPed(-1))
end

function DateToTimestamp(y, m, d, h, i, s)
    local time = 0
    if y then
        time = time + (y - 1970) * 31556926
    end
    if m then
        time = time + (m - 1) * 2629743
    end
    if d then
        time = time + (d - 1) * 86400
    end
    if h then
        time = time + h * 3600
    end
    if i then
        time = time + i * 60
    end
    if s then
        time = time + s
    end
    return math.ceil(time) - 14678
end

function GetCurrentParkingCar()
    local playerPed = GetPlayerPed(-1)
    local playerVeh = GetVehiclePedIsIn(playerPed, false)
    local vehPlate  = GetVehicleNumberPlateText(playerVeh)
    if _g.parkingVehicles then
        for id, vehicles in pairs(_g.parkingVehicles) do
            for plate, data in pairs(vehicles) do
                if plate == vehPlate then
                    return data
                end
            end
        end
    end
    return nil
end

function QuickVehicleHorn(vehicle, num)
    for i = 1, num do
        local timer = GetGameTimer()
        while GetGameTimer() - timer < 50 do
            SoundVehicleHornThisFrame(vehicle)
            Citizen.Wait(0)
        end
        Citizen.Wait(50)
    end
end

function PlayKeyAnim(vehicle)
    local playerPed = GetPlayerPed(-1)
    if playerPed and not IsEntityDead(playerPed) and not IsPedInAnyVehicle(playerPed) then
        local modelHash = GetHashKey("p_car_keys_01")
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(0)
        end
        local keyObject = CreateObject(modelHash, GetEntityCoords(playerPed), true, true, true)
        AttachEntityToEntity(keyObject, playerPed, GetPedBoneIndex(playerPed, 57005), 0.09, 0.03, -0.02, -76.0, 13.0, 28.0, false, true, true, true, 0, true)
        SetModelAsNoLongerNeeded(modelHash)
        ClearPedTasks(playerPed)
        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
        TaskTurnPedToFaceEntity(playerPed, vehicle, 500)
        local animDict = "anim@mp_player_intmenu@key_fob@"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(playerPed, animDict, "fob_click", 3.0, 1000, 51)
        PlaySoundFromEntity(-1, "Remote_Control_Fob", playerPed, "PI_Menu_Sounds", true, 0)
        Wait(1250)
        DetachEntity(keyObject, true, true)
        DeleteObject(keyObject)
        RemoveAnimDict(animDict)
        ClearPedTasksImmediately(playerPed)
    end
end

function GetParkingFeeByCar(data)
    if not data then return 0 end
    local localTime = _g.serverTime + math.floor((GetGameTimer() - _g.reciveTime) / 1000)
    local feeCalc   = Config.globalParking.enable and Config.globalParking.parkingFee or Config.parking[data.parking].parkingFee
    local parkFees  = math.ceil(((localTime - data.time) / 86400) * feeCalc)
    return parkFees
end

function GetCurrentTimestamp()
    local year, month, day, hour, minute, second = GetLocalTime()
    return DateToTimestamp(year, month, day, hour, minute, second)
end

-- Get key mapping
function GetKeyMapping(command)
    local hash = string.format('%08x', GetHashKey(command))
    if string.len(hash) > 8 then
        hash = string.sub(hash, 9)
    end
    return string.upper(('~INPUT_%s~'):format(hash))
end

-- Display help text
function DisplayHelpText(text)
	SetTextComponentFormat('STRING')
	AddTextComponentString(text)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function AdvancedDrawText3D(xyz, text)
    AddTextEntry(GetCurrentResourceName(), text)
    BeginTextCommandDisplayHelp(GetCurrentResourceName())
    EndTextCommandDisplayHelp(2, false, false, -1)
    SetFloatingHelpTextWorldPosition(1, xyz)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
end

function Draw2dText(x, y, scale, text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function IsParkingVehicle(vehicle)
    if NetworkGetEntityIsNetworked(vehicle) then
        return false
    end
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    if _g.parkingVehicles then
        for id, vehicles in pairs(_g.parkingVehicles) do
            for plate, data in pairs(vehicles) do
                if plate == vehiclePlate then
                    return true
                end
            end
        end
    end
    return false
end

-- Get vehicle properties
function GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then
        return {}
    end
    local color1, color2               = GetVehicleColours(vehicle)
	local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
	local c1r, c1g, c1b                = GetVehicleCustomPrimaryColour(vehicle)
	local c2r, c2g, c2b                = GetVehicleCustomSecondaryColour(vehicle)
	local customcolor1                 = { r = c1r, g = c1g, b = c1b }
	local customcolor2                 = { r = c2r, g = c2g, b = c2b }
	local modExtras                    = {}
	local windowIntact                 = {}
	local tyreBurst                    = {}
	local doorDamage                   = {}

	for i = 0, 14 do
		table.insert(modExtras, IsVehicleExtraTurnedOn(vehicle, i))
	end

	for i = 0, 7 do
		table.insert(windowIntact, IsVehicleWindowIntact(vehicle, i))
	end

	for i = 0, 5 do
		local complete = IsVehicleTyreBurst(vehicle, i, true)
		if complete then
			table.insert(tyreBurst, 2)
		else
			local onRim = IsVehicleTyreBurst(vehicle, i, false)
			table.insert(tyreBurst, onRim and 1 or 0)
		end
	end

	for i = 0, 5 do
		table.insert(doorDamage, IsVehicleDoorDamaged(vehicle, i))
	end

	return {
		model             = GetEntityModel(vehicle),
		plate             = GetVehicleNumberPlateText(vehicle),
		plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),
		health            = GetEntityHealth(vehicle),
		dirtLevel         = GetVehicleDirtLevel(vehicle),
		color1            = color1,
		color2            = color2,
		livery            = GetVehicleLivery(vehicle),
		bodyHealth        = GetVehicleBodyHealth(vehicle),
		engineHealth      = GetVehicleEngineHealth(vehicle),
		tankHealth        = GetVehiclePetrolTankHealth(vehicle),
		pearlescentColor  = pearlescentColor,
		wheelColor        = wheelColor,
		dashColor         = GetVehicleDashboardColor(vehicle),
		interiorColor     = GetVehicleInteriorColor(vehicle),
		wheels            = GetVehicleWheelType(vehicle),
		windowTint        = GetVehicleWindowTint(vehicle),
		tyresCanBurst     = GetVehicleTyresCanBurst(vehicle),
		neonEnabled       = {
			IsVehicleNeonLightEnabled(vehicle, 0),
			IsVehicleNeonLightEnabled(vehicle, 1),
			IsVehicleNeonLightEnabled(vehicle, 2),
			IsVehicleNeonLightEnabled(vehicle, 3)
		},
		neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
		tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),
		xenonColor        = GetVehicleXenonLightsColour(vehicle),
		modSpoilers       = GetVehicleMod(vehicle, 0),
		modFrontBumper    = GetVehicleMod(vehicle, 1),
		modRearBumper     = GetVehicleMod(vehicle, 2),
		modSideSkirt      = GetVehicleMod(vehicle, 3),
		modExhaust        = GetVehicleMod(vehicle, 4),
		modFrame          = GetVehicleMod(vehicle, 5),
		modGrille         = GetVehicleMod(vehicle, 6),
		modHood           = GetVehicleMod(vehicle, 7),
		modFender         = GetVehicleMod(vehicle, 8),
		modRightFender    = GetVehicleMod(vehicle, 9),
		modRoof           = GetVehicleMod(vehicle, 10),
		modEngine         = GetVehicleMod(vehicle, 11),
		modBrakes         = GetVehicleMod(vehicle, 12),
		modTransmission   = GetVehicleMod(vehicle, 13),
		modHorns          = GetVehicleMod(vehicle, 14),
		modSuspension     = GetVehicleMod(vehicle, 15),
		modArmor          = GetVehicleMod(vehicle, 16),
		modTurbo          = IsToggleModOn(vehicle, 18),
		modSmokeEnabled   = IsToggleModOn(vehicle, 20),
		modXenon          = IsToggleModOn(vehicle, 22),
		modFrontWheels    = GetVehicleMod(vehicle, 23),
		modBackWheels     = GetVehicleMod(vehicle, 24),
		modPlateHolder    = GetVehicleMod(vehicle, 25),
		modVanityPlate    = GetVehicleMod(vehicle, 26),
		modTrimA          = GetVehicleMod(vehicle, 27),
		modOrnaments      = GetVehicleMod(vehicle, 28),
		modDashboard      = GetVehicleMod(vehicle, 29),
		modDial           = GetVehicleMod(vehicle, 30),
		modDoorSpeaker    = GetVehicleMod(vehicle, 31),
		modSeats          = GetVehicleMod(vehicle, 32),
		modSteeringWheel  = GetVehicleMod(vehicle, 33),
		modShifterLeavers = GetVehicleMod(vehicle, 34),
		modAPlate         = GetVehicleMod(vehicle, 35),
		modSpeakers       = GetVehicleMod(vehicle, 36),
		modTrunk          = GetVehicleMod(vehicle, 37),
		modHydrolic       = GetVehicleMod(vehicle, 38),
		modEngineBlock    = GetVehicleMod(vehicle, 39),
		modAirFilter      = GetVehicleMod(vehicle, 40),
		modStruts         = GetVehicleMod(vehicle, 41),
		modArchCover      = GetVehicleMod(vehicle, 42),
		modAerials        = GetVehicleMod(vehicle, 43),
		modTrimB          = GetVehicleMod(vehicle, 44),
		modTank           = GetVehicleMod(vehicle, 45),
		modWindows        = GetVehicleMod(vehicle, 46),
		modLivery         = GetVehicleMod(vehicle, 48),
		modExtras		  = modExtras,
		windowIntact	  = windowIntact,
		tyreBurst		  = tyreBurst,
		doorDamage		  = doorDamage,
	}
end

-- Set vehicle properties
function SetVehicleProperties(vehicle, props)
    SetVehicleModKit(vehicle, 0)

	if props.plate ~= nil then
		SetVehicleNumberPlateText(vehicle, props.plate)
	end

	if props.plateIndex ~= nil then
		SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
	end

	if props.health ~= nil then
		SetEntityHealth(vehicle, props.health)
	end

	if props.dirtLevel ~= nil then
		SetVehicleDirtLevel(vehicle, props.dirtLevel)
	end

	if props.color1 ~= nil then
		local color1, color2 = GetVehicleColours(vehicle)
		SetVehicleColours(vehicle, props.color1, color2)
	end

	if props.color2 ~= nil then
		local color1, color2 = GetVehicleColours(vehicle)
		SetVehicleColours(vehicle, color1, props.color2)
	end

	if props.pearlescentColor ~= nil then
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
	end

	if props.wheelColor ~= nil then
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleExtraColours(vehicle, pearlescentColor, props.wheelColor)
	end

	if props.dashColor ~= nil then
		SetVehicleDashboardColor(vehicle, props.dashColor)
	end

	if props.interiorColor ~= nil then
		SetVehicleInteriorColor(vehicle, props.interiorColor)
	end

	if props.wheels ~= nil then
		SetVehicleWheelType(vehicle, props.wheels)
	end

	if props.windowTint ~= nil then
		SetVehicleWindowTint(vehicle, props.windowTint)
	end

	if props.tyresCanBurst ~= nil then
		SetVehicleTyresCanBurst(vehicle, tonumber(props.tyresCanBurst) == 1 and true or false)
	end

	if props.neonEnabled ~= nil then
		SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
		SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
		SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
		SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
	end

	if props.neonColor ~= nil then
		SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
	end
	
	if props.xenonColor ~= nil then
		SetVehicleXenonLightsColour(vehicle, props.xenonColor)
	end

	if props.modSmokeEnabled ~= nil then
		ToggleVehicleMod(vehicle, 20, true)
	end

	if props.tyreSmokeColor ~= nil then
		SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
	end

	if props.modSpoilers ~= nil then
		SetVehicleMod(vehicle, 0, props.modSpoilers, false)
	end

	if props.modFrontBumper ~= nil then
		SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
	end

	if props.modRearBumper ~= nil then
		SetVehicleMod(vehicle, 2, props.modRearBumper, false)
	end

	if props.modSideSkirt ~= nil then
		SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
	end

	if props.modExhaust ~= nil then
		SetVehicleMod(vehicle, 4, props.modExhaust, false)
	end

	if props.modFrame ~= nil then
		SetVehicleMod(vehicle, 5, props.modFrame, false)
	end

	if props.modGrille ~= nil then
		SetVehicleMod(vehicle, 6, props.modGrille, false)
	end

	if props.modHood ~= nil then
		SetVehicleMod(vehicle, 7, props.modHood, false)
	end

	if props.modFender ~= nil then
		SetVehicleMod(vehicle, 8, props.modFender, false)
	end

	if props.modRightFender ~= nil then
		SetVehicleMod(vehicle, 9, props.modRightFender, false)
	end

	if props.modRoof ~= nil then
		SetVehicleMod(vehicle, 10, props.modRoof, false)
	end

	if props.modEngine ~= nil then
		SetVehicleMod(vehicle, 11, props.modEngine, false)
	end

	if props.modBrakes ~= nil then
		SetVehicleMod(vehicle, 12, props.modBrakes, false)
	end

	if props.modTransmission ~= nil then
		SetVehicleMod(vehicle, 13, props.modTransmission, false)
	end

	if props.modHorns ~= nil then
		SetVehicleMod(vehicle, 14, props.modHorns, false)
	end

	if props.modSuspension ~= nil then
		SetVehicleMod(vehicle, 15, props.modSuspension, false)
	end

	if props.modArmor ~= nil then
		SetVehicleMod(vehicle, 16, props.modArmor, false)
	end

	if props.modTurbo ~= nil then
		ToggleVehicleMod(vehicle,  18, props.modTurbo)
	end

	if props.modXenon ~= nil then
		ToggleVehicleMod(vehicle,  22, props.modXenon)
	end

	if props.modFrontWheels ~= nil then
		SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
	end

	if props.modBackWheels ~= nil then
		SetVehicleMod(vehicle, 24, props.modBackWheels, false)
	end

	if props.modPlateHolder ~= nil then
		SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
	end

	if props.modVanityPlate ~= nil then
		SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
	end

	if props.modTrimA ~= nil then
		SetVehicleMod(vehicle, 27, props.modTrimA, false)
	end

	if props.modOrnaments ~= nil then
		SetVehicleMod(vehicle, 28, props.modOrnaments, false)
	end

	if props.modDashboard ~= nil then
		SetVehicleMod(vehicle, 29, props.modDashboard, false)
	end

	if props.modDial ~= nil then
		SetVehicleMod(vehicle, 30, props.modDial, false)
	end

	if props.modDoorSpeaker ~= nil then
		SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
	end

	if props.modSeats ~= nil then
		SetVehicleMod(vehicle, 32, props.modSeats, false)
	end

	if props.modSteeringWheel ~= nil then
		SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
	end

	if props.modShifterLeavers ~= nil then
		SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
	end

	if props.modAPlate ~= nil then
		SetVehicleMod(vehicle, 35, props.modAPlate, false)
	end

	if props.modSpeakers ~= nil then
		SetVehicleMod(vehicle, 36, props.modSpeakers, false)
	end

	if props.modTrunk ~= nil then
		SetVehicleMod(vehicle, 37, props.modTrunk, false)
	end

	if props.modHydrolic ~= nil then
		SetVehicleMod(vehicle, 38, props.modHydrolic, false)
	end

	if props.modEngineBlock ~= nil then
		SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
	end

	if props.modAirFilter ~= nil then
		SetVehicleMod(vehicle, 40, props.modAirFilter, false)
	end

	if props.modStruts ~= nil then
		SetVehicleMod(vehicle, 41, props.modStruts, false)
	end

	if props.modArchCover ~= nil then
		SetVehicleMod(vehicle, 42, props.modArchCover, false)
	end

	if props.modAerials ~= nil then
		SetVehicleMod(vehicle, 43, props.modAerials, false)
	end

	if props.modTrimB ~= nil then
		SetVehicleMod(vehicle, 44, props.modTrimB, false)
	end

	if props.modTank ~= nil then
		SetVehicleMod(vehicle, 45, props.modTank, false)
	end

	if props.modWindows ~= nil then
		SetVehicleMod(vehicle, 46, props.modWindows, false)
	end

	if props.modLivery ~= nil then
		SetVehicleMod(vehicle, 48, props.modLivery, false)
	end
	
	if props.livery ~= nil then
		SetVehicleLivery(vehicle, props.livery)
	end
	
	if props.bodyHealth ~= nil then
		SetVehicleBodyHealth(vehicle, props.bodyHealth)
	end
	
	if props.engineHealth ~= nil then
		SetVehicleEngineHealth(vehicle, props.engineHealth)
	end
	
	if props.tankHealth ~= nil then
		SetVehiclePetrolTankHealth(vehicle, props.tankHealth)
	end

	if props.modExtras ~= nil and type(props.modExtras) == 'table' then
		for k, v in pairs(props.modExtras) do
			SetVehicleExtra(vehicle, tonumber(k - 1), not v)
		end
	end

	if props.windowIntact ~= nil and type(props.windowIntact) == 'table' then
		for k, v in pairs(props.windowIntact) do
			if not v then
				SmashVehicleWindow(vehicle, k - 1)
			end
		end
	end

	if props.tyreBurst ~= nil and type(props.tyreBurst) == 'table' then
		for k, v in pairs(props.tyreBurst) do
			if v == 1 then
				SetVehicleTyreBurst(vehicle, k - 1, true, 0.0)
			elseif v == 2 then
				SetVehicleTyreBurst(vehicle, k - 1, true, 1000.0)
			end
		end
	end

	if props.doorDamage ~= nil and type(props.doorDamage) == 'table' then
		for k, v in pairs(props.doorDamage) do
			if v then
				SetVehicleDoorBroken(vehicle, k - 1, true)
			end
		end
	end
end

function GetVehicleDamageData(vehicle)
	if not vehicle or not DoesEntityExist(vehicle) then
		return false
	end
	local model    = GetEntityModel(vehicle)
	local min, max = GetModelDimensions(model)
	local position = GetDamagePositions(min, max)
	local damages  = {}
	for k, v in pairs(position) do
		local damagePos = GetVehicleDeformationAtPos(vehicle, v)
		if #(damagePos) > 0.05 then
			table.insert(damages, { pos = v, data = #(damagePos) })
		end
	end
	return damages
end

function SetVehicleDamageData(vehicle, damages)
	if not vehicle or not DoesEntityExist(vehicle) or type(damages) ~= 'table' then
		return
	end
	local model    = GetEntityModel(vehicle)
	local min, max = GetModelDimensions(model)
	local size     = #(max - min) * 40.0
	local handling = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDeformationDamageMult")
	local multiple = 20.0
	local num      = 0
	multipleList = { { k = 0.55, v = 1000.0 }, { k = 0.65, v = 400.0 }, { k = 0.75, v = 200.0 } }
	for k, v in pairs(multipleList) do
		if handling < v.k then
			multiple = v.v
			break
		end
	end
	for k, v in pairs(damages) do v.pos = vec3(v.pos.x, v.pos.y, v.pos.z) end
	while true do
		if not DoesEntityExist(vehicle) then break end
		local find = false
		for k, v in pairs(damages) do
			local damagePos = GetVehicleDeformationAtPos(vehicle, v.pos)
			if #(damagePos) < v.data then
				local offset = v.pos * 2.0
				local damage = v.data * multiple
				SetVehicleDamage(vehicle, offset.x, offset.y, offset.z, damage, size, true)
				find = true
			end
		end
		num = num + 1
		if num > 50 then break end
		Wait(1)
	end
end

function GetDamagePositions(min, max)
	local pos = {
		x = (max.x - min.x) * 0.5, y = (max.y - min.y) * 0.5,
		z = (max.z - min.z) * 0.5, h = (max.y - min.y) * 0.5 * 0.5,
	}
	return {
		vec3(-pos.x, pos.y, 0.0),  vec3(-pos.x, pos.y, pos.z),  vec3(0.0, pos.y, 0.0),
		vec3(0.0, -pos.y, pos.z),  vec3(pos.x, -pos.y, 0.0),    vec3(pos.x, -pos.y, pos.z),
		vec3(0.0, pos.y, pos.z),   vec3(pos.x, pos.y, 0.0),     vec3(pos.x, pos.y, pos.z),
		vec3(-pos.x, -pos.y, 0.0), vec3(-pos.x, -pos.y, pos.z), vec3(0.0, -pos.y, 0.0),
		vec3(-pos.x, pos.h, 0.0),  vec3(-pos.x, pos.h, pos.z),  vec3(0.0, pos.h, 0.0),
		vec3(0.0, -pos.h, pos.z),  vec3(pos.x, -pos.h, 0.0),    vec3(pos.x, -pos.h, pos.z),
		vec3(0.0, pos.h, pos.z),   vec3(pos.x, pos.h, 0.0),     vec3(pos.x, pos.h, pos.z),
		vec3(0.0, 0.0, pos.z),     vec3(pos.x, 0.0, 0.0),       vec3(pos.x, 0.0, pos.z),
		vec3(-pos.x, 0.0, 0.0),    vec3(-pos.x, 0.0, pos.z),    vec3(0.0, 0.0, 0.0),
		vec3(-pos.x, -pos.h, 0.0), vec3(-pos.x, -pos.h, pos.z), vec3(0.0, -pos.h, 0.0),
	}
end

RegisterNetEvent("zerodream_parking:triggerServerCallback")
AddEventHandler("zerodream_parking:triggerServerCallback", function(requestId, ...)
    local cb = _g.clientCallbacks[requestId]
    if not cb then
        error("TriggerServerCallback: callback not found with id '" .. requestId .. "'")
    end
    cb(...)
end)
