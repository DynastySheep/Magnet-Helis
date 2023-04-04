# Magnet-Helis

Lets you spawn cargobob and skylift with functioning magnets. Simply put the script in your Lua Scripts folder.

![MagnetHelis](https://user-images.githubusercontent.com/129829409/229707465-6650571d-eb59-474c-8b36-eca3362e7a4e.png)


## Useful notes:
Use **E** or **Right Arrow** if playing with controller to attach/detach vehicles to cargobob's magnet. It will always attach to the vehicle that the magnet is aiming at.

Skylift has it's own functions for attach/detach via menu since it doesn't have built in functions like cargobob with magnet afaik.

## Known bugs:
- Sometimes when you spawn cargobob, the magnet will freeze in place. Simple fix is to teleport to some other area and spawn it there first.

- Skylift's magnet will not lift vehicles that are occupied by other players. A workaround is to attach the vehicle first and then let the player go inside the attached vehicle. Don't think there is a way to change that apart from forcing  player to get out of the vehicle first - correct me if I'm wrong.

- Skylift positioning issue, I've based the attach coordinates on bus since it's the closest looking thing to a container. This means that if you lift up smaller vehicles, there will be a gap between vehicle and magnet. This is still something that I'm trying to figure out..
