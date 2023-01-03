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
        time = time + y * 31536000
    end
    if m then
        time = time + m * 2592000
    end
    if d then
        time = time + d * 86400
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
    return time
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

	for i = 0, 14 do
		table.insert(modExtras, IsVehicleExtraTurnedOn(vehicle, i) and 0 or 1)
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
			SetVehicleExtra(vehicle, tonumber(k - 1), tonumber(v))
		end
	end
end

RegisterNetEvent("zerodream_parking:triggerServerCallback")
AddEventHandler("zerodream_parking:triggerServerCallback", function(requestId, ...)
    local cb = _g.clientCallbacks[requestId]
    if not cb then
        error("TriggerServerCallback: callback not found with id '" .. requestId .. "'")
    end
    cb(...)
end)
