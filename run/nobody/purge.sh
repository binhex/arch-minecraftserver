#!/bin/bash

# script to remove any old minecraft worlds backups with a creation date older than value for env var 'PURGE_BACKUP_DAYS'

if [[ "${PURGE_BACKUP_DAYS}" -gt 0 ]]; then

	check_delay_hours=12

	while true; do

		if [[ -d /config/minecraft/backups ]]; then

			echo "[info] Removing any Minecraft worlds backups with a creation date older than ${PURGE_BACKUP_DAYS} days..."
			find /config/minecraft/backups/* -type d -mtime +"${PURGE_BACKUP_DAYS}" 2>/dev/null | xargs rm -rf

		fi

		echo "[info] Checking for old backups in ${check_delay_hours} hours..."
		sleep "${check_delay_hours}"h

	done

else

	echo "[info] Removal of old Minecraft worlds backup not enabled, env var 'PURGE_BACKUP_DAYS' value equal to '0'."

fi
