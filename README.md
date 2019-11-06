**Application**

[Minecraft Server](https://www.minecraft.net/en-us/download/server/)

**Description**

Minecraft is a sandbox video game created by Swedish game developer Markus Persson and released by Mojang in 2011. The game allows players to build with a variety of different blocks in a 3D procedurally generated world, requiring creativity from players. Other activities in the game include exploration, resource gathering, crafting, and combat. Multiple game modes that change gameplay are available, including—but not limited to—a survival mode, in which players must acquire resources to build the world and maintain health, and a creative mode, where players have unlimited resources to build with.

**Build notes**

Latest stable Minecraft release from Arch Linux AUR.

**Usage**
```
docker run -d \
    -p 25565:25565 \
    --name=<container name> \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e MAX_BACKUPS=<max number of minecraft backups> \
    -e JAVA_INITIAL_HEAP_SIZE=<java initial heap size in megabytes> \
    -e JAVA_MAX_HEAP_SIZE=<java max heap size in megabytes> \
    -e JAVA_MAX_THREADS=<java max number of threads> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-minecraftserver
```

Please replace all user variables in the above command defined by <> with the correct values.

**Example**
```
docker run -d \
    -p 25565:25565 \
    --name=minecraftserver \
    -v /apps/docker/minecraftserver:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e MAX_BACKUPS=10 \
    -e JAVA_INITIAL_HEAP_SIZE=512M \
    -e JAVA_MAX_HEAP_SIZE=1024M \
    -e JAVA_MAX_THREADS=1 \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-minecraftserver
```

**Notes**

JAVA_INITIAL_HEAP_SIZE value and JAVA_MAX_HEAP_SIZE values must be a multiple of 1024 and greater than 2MB.

If you want to connect to the minecraft server console then issue the following command, use CTRL+a and then press 'd' to disconnect from the session, leaving it running.

```
docker exec -u nobody -t <name of container> /usr/bin/minecraftd console
```

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/84880-support-binhex-minecraftserver/)