# ZeroDream Parking
A car parking script for FiveM

## Preview video

[![image](https://user-images.githubusercontent.com/34357771/210299479-b71f3ad1-b08b-4189-a0ec-9374a259d23c.png)](https://youtu.be/UH77hUi-KkI)

## Features

- Store the car like the real life, the car will not disappear when you are offline.
- Standalone script, it can use without framework.
- ESX / QBCore or other custom framework support.
- You can park your car anywhere.
- Parking fees for player.
- Custom key binds support.
- Optimized performance (0.01ms in common, 0.05ms when close to vehicles).

## IMPORTANT
**!!! CHANGE THE KEY BINDS BEFORE YOU START IT !!!**<br>
**!!! CHANGE THE KEY BINDS BEFORE YOU START IT !!!**<br>
**!!! CHANGE THE KEY BINDS BEFORE YOU START IT !!!**<br>

This script is using `RegisterKeyMapping`, when you run the script, the key bindings are sent to the clients, you cannot modify them again by changing the configuration, every player needs to change it in pause menu by themselves.

## Requirements

- [mysql-async](https://github.com/brouznouf/fivem-mysql-async) (or oxmysql)
- [esx_vehicleshop](https://github.com/bathorus/esx_vehicleshop) (optional)

## Download

#### Using Git

```
git clone https://github.com/kasuganosoras/zerodream_parking
```

#### Manually

- Download [Zip File](https://github.com/kasuganosoras/zerodream_parking/archive/master.zip)
- Unzip the archive and rename the folder to `zerodream_parking`
- Put it in your `resources` folder

## Installation

- Add `ensure zerodream_parking` to your `server.cfg`.
- Restart your server, **the script will create the database table automatically**.
- Restart your server again.

## Commands

| name | args | description |
| ---- | ---- | ----------- |
| /impound | `<plate>` | Impound a car and remove it from the parking |
| /findveh | `<plate>` | Find a car by plate number |

## Custom API

All the code related to the framework or balance system is in the `client/api.lua` and `server/api.lua` file, you can modify it to fit your needs.

By default, I have added the ESX support, you can change the framework type in `config.lua` to `esx` to enable it.

## Configuration
Here is an example configuration file

```lua
Config = {

    -- Debug mode
    debug       = false,

    -- Locale (en / zh / es)
    locale      = 'en',

    -- Which framework you are using, can be 'standalone', 'esx', 'esx1.9' or 'qbcore'
    framework   = 'standalone',

    -- Require stop the engine before parking car?
    stopEngine  = true,

    -- Allow park not owned vehicles?
    notOwnedCar = true,

    -- Locked car for everyone (included owner)?
    lockedCar   = true,

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
        allowTypes = { -1 }, -- if you want to allow all class, change to { -1 },
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
```

## Legal

### License

zerodream_parking - Standalone car parking script for FiveM

Copyright (C) 2023 Akkariin

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.
