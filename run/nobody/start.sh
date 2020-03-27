#!/bin/bash

# if minecraft folder doesnt exist then copy default to host config volume
if [ ! -d "/config/minecraft" ]; then

	echo "[info] Minecraft folder doesn't exist, copying default to '/config/minecraft/'..."

	mkdir -p /config/minecraft
	if [[ -d "/srv/minecraft" ]]; then
		cp -R /srv/minecraft/* /config/minecraft/ 2>/dev/null || true
	fi

else

	echo "[info] Minecraft folder '/config/minecraft' already exists, rsyncing newer files..."
	rsync -rltp --exclude 'world' --exclude '/server.properties' --exclude '/*.json' /srv/minecraft/ /config/minecraft

fi

if [ ! -f /config/minecraft/eula.txt ]; then

	echo "[info] Starting Minecraft Java process to force creation of eula.txt..."
	/usr/bin/minecraftd start

	echo "[info] Waiting for Minecraft Java process to abort (expected, due to eula flag not set)..."
	while pgrep -fa "java" > /dev/null; do
		sleep 0.1
	done
	echo "[info] Minecraft Java process ended (expected)"

	echo "[info] Setting EULA to true..."
	sed -i -e 's~eula=false~eula=true~g' '/config/minecraft/eula.txt'
	echo "[info] EULA set to true"

fi

echo "[info] Starting Minecraft Java process..."
/usr/bin/minecraftd start
echo "[info] Minecraft Java process is running"
cat
