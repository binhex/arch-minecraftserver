#!/bin/bash

# script to do a manual backup of minecraft worlds in a safe manner, using the save commands via screen

function run_console_command() {

	screen_message="${1}"
	console_command="${2}"

	retry_count=6

	while ! tail -n 5 '/config/minecraft/logs/screen.log' | grep -q -P "${screen_message}"; do

		screen -r minecraft -p 0 -X stuff "${console_command}^M"
		retry_count=$((retry_count-1))

		if [ "${retry_count}" -eq "0" ]; then

			echo "[warn] Minecraft console did not confirm message '${screen_message}', giving up waiting..."
			return 1

		fi

		echo "[info] Waiting for Minecraft console message '${screen_message}', ${retry_count} retries left..."
		sleep 10s

	done
	return 0

}

if [[ "${CREATE_BACKUP_HOURS}" -gt 0 ]]; then

	while true; do

		echo "[info] Waiting ${CREATE_BACKUP_HOURS} hours before running worlds backup..."
		sleep "${CREATE_BACKUP_HOURS}"h

		if [ ! -f '/config/minecraft/logs/screen.log' ]; then
			echo "[warn] Screen logging of the Minecraft console is not enabled, exiting backup script..."; exit 1
		fi

		echo "[info] Starting Minecraft worlds backup..."

		# removing any currently attached sessions (such as web ui console) as you cannot execute 'stuff' whilst another session is connected
		screen -D

		# removing any dead sessions
		screen -wipe

		echo "[info] Run Minecraft console command to set Minecraft worlds ready for backup..."
		run_console_command 'Automatic saving is now disabled|Saving is already turned off' 'save-off'
		run_console_command 'Saved the game' 'save-all'

		if [ "${?}" -eq 0 ]; then

			# get current datetime
			datetime=$(date +%Y%m%d-%H%M%S)

			# create backup sub folder to store backups of worlds
			mkdir -p "/config/minecraft/backups/${datetime}"

			echo "[info] Minecraft worlds are now ready for backup, backing up to '/config/minecraft/backups/${datetime}/'..."
			cp -R "/config/minecraft/world" "/config/minecraft/backups/${datetime}"

		fi

		echo "[info] Setting Minecraft back to 'save-on'..."
		run_console_command 'Automatic saving is now enabled|Saving is already turned on' 'save-on'

		echo "[info] Minecraft worlds backup complete"

		# restart webui console as it may of been terminated due to forced detachment (see above)
		nohup /home/nobody/webui.sh >> '/config/supervisord.log' &

	done

else

	echo "[info] Minecraft worlds backup not enabled, env var 'CREATE_BACKUP_HOURS' value equal to '0'."

fi
