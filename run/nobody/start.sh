#!/bin/bash


function copy_minecraft(){

	if [[ -z "${CUSTOM_JAR_PATH}" || "${CUSTOM_JAR_PATH}" == '/config/minecraft/minecraft_server.jar' ]]; then

		# if minecraft server.properties file doesnt exist then copy default to host config volume
		if [ ! -f "/config/minecraft/server.properties" ]; then

			echo "[info] Minecraft 'server.properties' file doesnt exist, copying default installation from '/srv/minecraft' to '/config/minecraft/'..."

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

	fi

}

function accept_eula() {

	if [[ -z "${CUSTOM_JAR_PATH}" || "${CUSTOM_JAR_PATH}" == '/config/minecraft/minecraft_server.jar' ]]; then

		eula_filepath="/config/minecraft/eula.txt"

	else

		eula_path="$(dirname "${CUSTOM_JAR_PATH}")"
		eula_filepath="${eula_path}/eula.txt"

	fi

	if [ ! -f "${eula_filepath}" ]; then

		echo "[info] EULA file does not exist at '${eula_filepath}', creating..."
		echo 'eula=true' > "${eula_filepath}"

	else

		echo "[info] EULA file exists, checking EULA is set to 'true'..."
		grep -q 'eula=true' < "${eula_filepath}"

		if [ "${?}" -eq 0 ]; then

			echo "[info] EULA set to 'true'"

		else

			echo "[info] EULA set to 'false', changing to 'true'..."
			echo 'eula=true' > "${eula_filepath}"

		fi

	fi

}

function start_minecraft() {

	# create logs sub folder to store screen output from console
	mkdir -p /config/minecraft/logs

	# run screen attached to minecraft (daemonized, non-blocking) to allow users to run commands in minecraft console
	echo "[info] Starting Minecraft Java process..."
	screen -L -Logfile '/config/minecraft/logs/screen.log' -d -S minecraft -m bash -c "cd /config/minecraft && java -Xms${JAVA_INITIAL_HEAP_SIZE} -Xmx${JAVA_MAX_HEAP_SIZE} -XX:ParallelGCThreads=${JAVA_MAX_THREADS} -jar ${CUSTOM_JAR_PATH} nogui"
	echo "[info] Minecraft Java process is running"
	if [[ ! -z "${STARTUP_CMD}" ]]; then
		startup_cmd
	fi

}

function startup_cmd() {

	# split comma separated string into array from STARTUP_CMD env variable
	IFS=',' read -ra startup_cmd_array <<< "${STARTUP_CMD}"

	# process startup cmds in the array
	for startup_cmd_item in "${startup_cmd_array[@]}"; do
		echo "[info] Executing startup Minecraft command '${startup_cmd_item}'"
		screen -S minecraft -p 0 -X stuff "${startup_cmd_item}^M"
	done

}

# copy/rsync minecraft to /config
copy_minecraft

# accept eula
accept_eula

# start minecraft
start_minecraft

# run webui script
source /home/nobody/webui.sh
