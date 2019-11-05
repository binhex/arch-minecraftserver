#!/bin/bash

# if minecraft folder exists in container then rename
if [[ -d "/srv/minecraft" && ! -L "/srv/minecraft" ]]; then
	mv /srv/minecraft /srv/minecraft-backup 2>/dev/null || true
fi

# if minecraft folder doesnt exist then copy default to host config volume (soft linked)
if [ ! -d "/config/minecraft" ]; then

	echo "[info] minecraft folder doesnt exist, copying default to /config/minecraft/..."

	mkdir -p /config/minecraft
	if [[ -d "/srv/minecraft-backup" && ! -L "/srv/minecraft-backup" ]]; then
		cp -R /srv/minecraft-backup/* /config/minecraft/ 2>/dev/null || true
	fi

else

	echo "[info] minecraft folder already exists, skipping copy"

fi

# create soft link to minecraft folder
ln -fs /config/minecraft /srv

if [ ! -f /config/minecraft/eula.txt ]; then

	echo "[info] Starting Java (minecraft) process to force creation of eula.txt..."
	# start minecraft server for the first time to force generation of the eula.txt (will abort as eula not accepted)
	/usr/bin/minecraftd start

	echo "[info] Waiting for Java (minecraft) process to abort (expected, due to eula flag not set)..."
	while pgrep -fa "java" > /dev/null; do
		sleep 0.1
	done
	echo "[info] Java (minecraft) process ended"

	echo "[info] Setting eula to true..."
	sed -i -e 's~eula=false~eula=true~g' '/config/minecraft/eula.txt'
	echo "[info] eula set to true"

fi

echo "[info] Starting Java (minecraft) process..."
/usr/bin/minecraftd start
echo "[info] Java (minecraft) process started, successful start"

# /usr/bin/minecraftd is dameonised, thus we need to run something in foreground to prevent exit of script
cat