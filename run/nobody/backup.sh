#!/bin/bash

# script to do a manual backup of minecraft worlds in a safe manner, using the save commands via screen

if [[ "${CREATE_BACKUP_HOURS}" -gt 0 ]]; then

	# create backup sub folder to store backups of worlds
	mkdir -p /config/minecraft/backups

	while true; do

		retry_count=10

		echo "[info] Waiting ${CREATE_BACKUP_HOURS} hours before running worlds backup..."
		sleep "${CREATE_BACKUP_HOURS}"h

		if [ ! -f '/config/minecraft/logs/screen.log' ]; then
			echo "[warn] Screen logging of the Minecraft console is not enabled, exiting backup script..."; exit 1
		fi

		echo "[info] Starting Minecraft worlds backup..."

		echo "[info] Run Minecraft console command to set Minecraft worlds ready for backup..."
		screen -r minecraft -p 0 -X stuff "save hold^M"

		while ! tail -n 5 '/config/minecraft/logs/screen.log' | grep -q 'Data saved. Files are now ready to be copied.'; do

			screen -r minecraft -p 0 -X stuff "save query^M"
			retry_count=$((retry_count-1))

			if [ "${retry_count}" -eq "0" ]; then

				echo "[warn] Unable to obtain Minecraft worlds in hold state, giving up waiting..."
				break

			fi

			echo "[info] Waiting for Minecraft databases to be ready for backup, ${retry_count} retries left..."
			sleep 6s

		done

		if [ "${retry_count}" -gt "0" ]; then

			echo "[info] Minecraft worlds are now ready for backup, backing up to '/config/minecraft/backups/$(date +%Y%m%d-%H%M%S)/'..."
			cp -R "/config/minecraft/worlds" "/config/minecraft/backups/$(date +%Y%m%d-%H%M%S)"

		fi

		echo "[info] Setting Minecraft back to resume to allow any deferred writes..."
		screen -r minecraft -p 0 -X stuff "save resume^M"

		echo "[info] Minecraft worlds backup complete"

	done

else

	echo "[info] Minecraft worlds backup not enabled, env var 'CREATE_BACKUP_HOURS' value equal to '0'."

fi
