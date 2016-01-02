![Counter-Split](https://img.skyenet.org/~skyenet/projects/countersplit/logo-white.png)


### Description

Counter-Split allows automated usage of external timer programs such as Wsplit, Llanfair and LiveSplit with Counter-Strike: Source.

It is designed to provide the benefits of local timers such as tracking records and segments without the hassle of hosting and configuring a server-side timer, or the distraction of pressing hotkeys to manually advance splits.

### Features

* Automatically start and stop timer when leaving defined zones.
* Advance splits when entering checkpoint zones automatically.
* Dynamically load zone and checkpoint data upon map change.
* Supports local demo playback and first-person spectating.
* Supports any gamemode such as surf, bunnyhop, kreedz, etc.
* Can be used offline or while connected to an online server.
* Easily ported to other Source games such as CS:GO or TF2.

### Usage

*Pre-built versions of Counter-Split can be found on the [Releases](https://github.com/aixxe/CounterSplit/releases/) page.*

Counter-Split depends on Lua modules [RemoteProcess](https://github.com/aixxe/RemoteProcess) for interacting with the game process and FFI for miscellaneous C functions.

Two memory addresses are used to read the camera position and current map name. A tutorial for finding offsets [can be found here](https://github.com/aixxe/CounterSplit/wiki/Finding-game-offsets).

Counter-Split must be started while the game is running.

```
luajit.exe CounterSplit.lua
```

It is also possible to specify a configuration file as a command-line argument. This is especially helpful when using different games.

```
luajit.exe CounterSplit.lua includes\config.hl2dm.lua
luajit.exe CounterSplit.lua includes\config.csgo.lua
luajit.exe CounterSplit.lua includes\config.tf2.lua
```

### Demonstration

[![Video of Counter-Split in action](http://img.youtube.com/vi/V1EbHoTWB_Y/0.jpg)](http://www.youtube.com/watch?v=V1EbHoTWB_Y)