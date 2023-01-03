Config = {

    -- Debug mode
    debug       = false,

    -- Locale (en / zh)
    locale      = 'zh',

    -- Which framework you are using, can be 'standalone' or 'esx'
    framework   = 'esx',

    -- Require stop the engine before parking car?
    stopEngine  = true,

    -- Allow park not owned vehicles?
    notOwnedCar = true,

    -- Parking card item name
    parkingCard = 'parkingcard',

    -- Command settings, use false to disable (Only can disable engine control / find vehicle)
    commands    = {
        -- Control engine command
        engineControl  = 'enginecontrol',
        -- Park vehicle command
        parkingVehicle = 'parkingvehicle',
        -- Find the vehicle command
        findVehicle    = 'findveh',
    },

    -- Default key binding, use false to disable, player can change key binding in pause menu > settings > key binding > FiveM
    keyBinding  = {
        -- Turn on/off engine
        engineControl  = 'G',
        -- Park vehicle
        parkingVehicle = 'L',
    },

    -- Impound settings
    impound     = {
        command = 'impound',
        job     = { 'police', 'admin' },
    },

    -- Parking setting
    parking     = {
        -- Parking id, should be unique, DO NOT USE 'global' AS PARKING ID
        ['parking_1']  = {
            -- Parking name
            name       = 'Parking 1',
            -- Parking position
            pos        = vec3(-320.1, -921.38, 30.0),
            -- The parking size
            size       = 50.0,
            -- Max cars can be parked in this parking
            maxCars    = 10,
            -- Allow vehicle class, can be find here: https://docs.fivem.net/natives/?_0x29439776AAA00A62 (use -1 means all, use , to separate multiple types)
            allowTypes = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, -- if you want to allow all class, change to { -1 },
            -- Parking fee per day in real life time
            parkingFee = 1000,
            -- Display notification?
            notify     = true,
            -- White list, can be identifier, ip and job name, player will not need to pay parking fee if they are in the whitelist
            whitelist  = {
                'identifier.steam:110000131d62281',
                'ip.127.0.0.1',
                'job.admin',
            },
            -- Black list of vehicle model
            blacklist  = {
                'adder',
                'banshee',
            },
        },
    },

    -- Global parking
    globalParking = {
        -- if true, player can park their vehicle in any where
        enable     = true,
        -- Max cars can be parked on the map
        maxCars    = 100,
        -- Allow vehicle class, can be find here: https://docs.fivem.net/natives/?_0x29439776AAA00A62 (use -1 means all, use , to separate multiple types)
        allowTypes = { 0, 1, 2, 3, 4, 5 }, -- if you want to allow all class, change to { -1 },
        -- Render distance
        distance   = 50.0,
        -- Parking fee per day in real life time
        parkingFee = 1000,
        -- white list, can be identifier, ip and job name, player will not need to pay parking fee if they are in the whitelist
        whitelist  = {
            'identifier.steam:110000131d62281',
            'ip.127.0.0.1',
            'job.admin',
        },
        -- Black list of vehicle model
        blacklist  = {
            'adder',
            'banshee',
        },
    }
}