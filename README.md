# ZeroDream Parking
A car parking script for FiveM

## Preview video

[![image](https://user-images.githubusercontent.com/34357771/210299479-b71f3ad1-b08b-4189-a0ec-9374a259d23c.png)](https://youtu.be/UH77hUi-KkI)

## Features

- Store the car like the real life
- Standalone script
- ESX / Custom framework support
- Parking anywhere
- Parking fees for player
- Custom keybinds support
- Optimized performance

## Requirements

- [mysql-async](https://github.com/brouznouf/fivem-mysql-async)
- [esx_vehicleshop](https://github.com/bathorus/esx_vehicleshop) (optional)

## Download & Installation

#### Using Git

```
git clone https://github.com/kasuganosoras/zerodream_parking
```

#### Manually

- Download [Zip File](https://github.com/kasuganosoras/zerodream_parking/archive/master.zip)
- Unzip the archive and rename the folder to `zerodream_parking`
- Put it in your `resources` folder

## Installation

- Add `ensure zerodream_parking` to your `server.cfg`
- Restart your server, the script will automatically create the database table
- Restart your server again

## Custom API

All the code related to the framework or balance system is in the `client/api.lua` and `server/api.lua` file, you can modify it to fit your needs.

By default, I have added the ESX support, you can change the framework type in `config.lua` to `esx` to enable it.

## Legal

### License

zerodream_parking - Standalone car parking script for FiveM

Copyright (C) 2023 Akkariin

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.
