#!/bin/bash

function accept_eula() {

	if [ ! -f '/config/minecraft/eula.txt' ]; then

		echo "[info] Starting Minecraft Java process to force creation of 'eula.txt'..."
		start_minecraft

		echo "[info] Waiting for Minecraft Java process to abort (expected, due to eula flag not set)..."
		while pgrep -fu "nobody" "java" > /dev/null; do
			sleep 0.1
		done
		echo "[info] Minecraft Java process ended (expected)"

	fi

	echo "[info] Checking EULA is set to 'true'..."
	cat '/config/minecraft/eula.txt' | grep -q 'eula=true'

	if [ "${?}" -eq 0 ]; then
		echo "[info] EULA set to 'true'"
	else
		echo "[info] EULA set to 'false', changing to 'true'..."
		sed -i -e 's~eula=false~eula=true~g' '/config/minecraft/eula.txt'
	fi

}

function start_minecraft() {

	# create logs sub folder to store screen output from console
	mkdir -p /config/minecraft/logs

	# run screen attached to minecraft (daemonized, non-blocking) to allow users to run commands in minecraft console
	echo "[info] Starting Minecraft Java process..."
	screen -L -Logfile '/config/minecraft/logs/screen.log' -d -S minecraft -m bash -c "cd /config/minecraft && java -Xms${JAVA_INITIAL_HEAP_SIZE} -Xmx${JAVA_MAX_HEAP_SIZE} -XX:ParallelGCThreads=${JAVA_MAX_THREADS} -jar ${CUSTOM_JAR_PATH} nogui"
	echo "[info] Minecraft Java process is running"

}

# if minecraft server.properties file doesnt exist then copy default to host config volume
if [ ! -f "/config/minecraft/server.properties" ]; then

	echo "[info] Minecraft server.properties file doesnt exist, copying default installation to '/config/minecraft/'..."

	mkdir -p /config/minecraft
	if [[ -d "/srv/minecraft" ]]; then
		cp -R /srv/minecraft/* /config/minecraft/ 2>/dev/null || true
	fi

else

	# rsync options defined as follows:-
	# -r = recursive copy to destination
	# -l = copy source symlinks as symlinks on destination
	# -t = keep source modification times for destination files/folders
	# -p = keep source permissions for destination files/folders
	echo "[info] Minecraft folder '/config/minecraft' already exists, rsyncing newer files..."
	rsync -rltp --exclude 'world' --exclude '/server.properties' --exclude '/*.json' /srv/minecraft/ /config/minecraft

fi

# accept eula
accept_eula

# start minecraft
start_minecraft

# run webui script
source /home/nobody/webui.sh
