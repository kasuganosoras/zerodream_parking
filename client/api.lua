-- You can implement your custom API here

-- Get vehicle extra data, you can use this to store extra data (such as fuel) for the vehicle to database
-- Args: (number) vehicle
-- Return: table
function GetVehicleExtraData(vehicle)
    -- For Standalone
    return {}
end

-- Set vehicle extra data
-- Args: (number) vehicle, (table) data
function SetVehicleExtraData(vehicle, data)
    -- For Standalone
    -- Do nothing
end

-- Send notification to player
-- Args: (string) message
function SendNotification(message)
    -- For ESX
    if Config.framework == 'esx' then
        _g.ESX.ShowNotification(message)
        return
    end

    -- For Standalone
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end
