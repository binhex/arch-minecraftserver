**Application**

[Minecraft Server](https://www.minecraft.net/en-us/download/server/)

**Description**

Minecraft is a sandbox video game created by Swedish game developer Markus Persson and released by Mojang in 2011. The game allows players to build with a variety of different blocks in a 3D procedurally generated world, requiring creativity from players. Other activities in the game include exploration, resource gathering, crafting, and combat. Multiple game modes that change gameplay are available, including—but not limited to—a survival mode, in which players must acquire resources to build the world and maintain health, and a creative mode, where players have unlimited resources to build with.

**Build notes**

Latest stable Minecraft Java release from Mojang.

**Usage**
```
docker run -d \
    -p <host port>:8222/tcp \
    -p <host port>:25565 \
    --name=<container name> \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e CREATE_BACKUP_HOURS=<frequency of world backups in hours> \
    -e PURGE_BACKUP_DAYS=<specify oldest world backups to keep in days> \
    -e ENABLE_WEBUI_CONSOLE=<yes|no> \
    -e ENABLE_WEBUI_AUTH=<yes|no> \
    -e WEBUI_USER=<specify webui username> \
    -e WEBUI_PASS=<specify webui password> \
    -e WEBUI_CONSOLE_TITLE=<specify webui console title> \
    -e CUSTOM_JAR_PATH=<path to custom jar> \
    -e JAVA_VERSION=<8|11|latest> \
    -e JAVA_INITIAL_HEAP_SIZE=<java initial heap size in megabytes> \
    -e JAVA_MAX_HEAP_SIZE=<java max heap size in megabytes> \
    -e JAVA_MAX_THREADS=<java max number of threads> \
    -e STARTUP_CMD=<minecraft console command to execute on startup> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-minecraftserver
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access Minecraft Server console**

Requires `-e ENABLE_WEBUI_CONSOLE=yes`

`http://<host ip>:8222`

**Example**
```
docker run -d \
    -p 8222:8222/tcp \
    -p 25565:25565 \
    --name=minecraftserver \
    -v /apps/docker/minecraftserver:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e CREATE_BACKUP_HOURS=12 \
    -e PURGE_BACKUP_DAYS=14 \
    -e ENABLE_WEBUI_CONSOLE=yes \
    -e ENABLE_WEBUI_AUTH=yes \
    -e WEBUI_USER=admin \
    -e WEBUI_PASS=minecraft \
    -e WEBUI_CONSOLE_TITLE='Minecraft Server' \
    -e CUSTOM_JAR_PATH=/config/minecraft/paperclip.jar \
    -e JAVA_VERSION=latest \
    -e JAVA_INITIAL_HEAP_SIZE=512M \
    -e JAVA_MAX_HEAP_SIZE=1024M \
    -e JAVA_MAX_THREADS=1 \
    -e STARTUP_CMD=gamerule reducedDebugInfo true \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-minecraftserver
```

**Notes**

If you do **NOT** want world backups and/or purging of backups then set the value to '0' for env vars 'CREATE_BACKUP_HOURS' and/or 'PURGE_BACKUP_DAYS'.

Env var 'CUSTOM_JAR_PATH' is optional and allows you to define a specific jar to run, if not specified then the latest Mojang Minecraft jar will be used.

Env vars 'JAVA_INITIAL_HEAP_SIZE' value and 'JAVA_MAX_HEAP_SIZE' values must be a multiple of 1024 and greater than 2MB.

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/84880-support-binhex-minecraftserver/)