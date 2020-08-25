#!/bin/bash

# script to create a webui minecraft console using utility 'gotty'

if [[ "${ENABLE_WEBUI_CONSOLE}" == "yes" ]]; then

	if [[ "${ENABLE_WEBUI_AUTH}" == "yes" ]]; then
		credentials=" --credential ${WEBUI_USER}:${WEBUI_PASS}"
	fi

	echo "[info] Starting Minecraft console Web UI..."
	# note - do NOT quote the credentials, it will not start otherwise
	gotty --port=8222 --title-format "${WEBUI_CONSOLE_TITLE}" ${credentials} --permit-write screen -x minecraft

else

	echo "[info] Minecraft console Web UI not enabled"

fi
