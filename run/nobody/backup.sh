#!/bin/bash

# script to do a manual backup of minecraft worlds in a safe manner, using the save commands via screen

function run_console_command() {

	screen_message="${1}"
	console_command="${2}"

	retry_count=10

	while ! tail -n 5 '/config/minecraft/logs/screen.log' | grep -q "${screen_message}"; do

		screen -r minecraft -p 0 -X stuff "${console_command}^M"
		retry_count=$((retry_count-1))

		if [ "${retry_count}" -eq "0" ]; then

			echo "[warn] Unable to obtain Minecraft worlds in saved state, giving up waiting..."
			return 1

		fi

		echo "[info] Waiting for Minecraft databases to be ready for backup, ${retry_count} retries left..."
		sleep 6s

	done
	return 0

}

if [[ "${CREATE_BACKUP_HOURS}" -gt 0 ]]; then

	# create backup sub folder to store backups of worlds
	mkdir -p /config/minecraft/backups

	while true; do

		echo "[info] Waiting ${CREATE_BACKUP_HOURS} hours before running worlds backup..."
		sleep "${CREATE_BACKUP_HOURS}"h

		if [ ! -f '/config/minecraft/logs/screen.log' ]; then
			echo "[warn] Screen logging of the Minecraft console is not enabled, exiting backup script..."; exit 1
		fi

		echo "[info] Starting Minecraft worlds backup..."

		echo "[info] Run Minecraft console command to set Minecraft worlds ready for backup..."
		run_console_command 'Automatic saving is now disabled' 'save-off'
		run_console_command 'Saved the game' 'save-all'

		if [ "${?}" -eq 0 ]; then

			echo "[info] Minecraft worlds are now ready for backup, backing up to '/config/minecraft/backups/$(date +%Y%m%d-%H%M%S)/'..."
			cp -R "/config/minecraft/world" "/config/minecraft/backups/$(date +%Y%m%d-%H%M%S)"

		fi

		echo "[info] Setting Minecraft back to resume to allow any deferred writes..."
		run_console_command 'Automatic saving is now enabled' 'save-on'

		echo "[info] Minecraft worlds backup complete"

	done

else

	echo "[info] Minecraft worlds backup not enabled, env var 'CREATE_BACKUP_HOURS' value equal to '0'."

fi
