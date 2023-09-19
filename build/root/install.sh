#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from build arg, stripped of build ver using string manipulation
RELEASETAG="${1//-[0-9][0-9]/}"

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# detect image arch
####

# get target arch from Dockerfile argument
TARGETARCH="${2}"

# pacman packages
####

# define pacman packages
pacman_packages="jre8-openjdk-headless jre11-openjdk-headless jre17-openjdk-headless jre-openjdk-headless screen rsync"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages=""

# call aur install script (arch user repo)
source aur.sh

# github packages
####

# download gotty which gives us minecraft console in web ui
if [[ "${TARGETARCH}" == "x86-64" ]]; then
	github.sh --install-path /usr/bin --github-owner yudai --github-repo gotty --download-assets gotty_linux_amd64.tar.gz
elif [[ "${TARGETARCH}" == "aarch64" ]]; then
	github.sh --install-path /usr/bin --github-owner yudai --github-repo gotty --download-assets gotty_linux_arm.tar.gz
fi

# custom
####

# get json for latest 'release'
release_json=$(rcurl.sh -s 'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json' |  jq '[.versions[] | select(.type=="release")][0]')

# identify minecraft version
id=$(echo "${release_json}" | jq -r .id)
echo "[info] Minecraft Java version is '${id}'"

# check release tag name matches version from json
if [[ "${RELEASETAG}" != "${id}" ]]; then
	echo "[warn] Release tag name from build arg '${RELEASETAG}' does not match id '${id}' from json, exiting script..."
	exit 1
fi

# identify minecraft download url json
url_json=$(echo "${release_json}" | jq -r .url)
echo "[info] Minecraft Java JSON URL is '${url_json}'"

# identify minecraft download url
url_download=$(rcurl.sh -s "${url_json}" | jq -r .downloads.server.url)
echo "[info] Minecraft Java download URL is '${url_download}'"

# download compiled minecraft java server
rcurl.sh -o "/tmp/minecraft_server.jar" "${url_download}"

# move minecraft java server
mkdir -p "/srv/minecraft" && mv "/tmp/minecraft_server.jar" "/srv/minecraft/"

# container perms
####

# define comma separated list of paths
install_paths="/srv/minecraft,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export CREATE_BACKUP_HOURS=$(echo "${CREATE_BACKUP_HOURS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${CREATE_BACKUP_HOURS}" ]]; then
	echo "[info] CREATE_BACKUP_HOURS defined as '${CREATE_BACKUP_HOURS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] CREATE_BACKUP_HOURS not defined,(via -e CREATE_BACKUP_HOURS), defaulting to '12'" | ts '%Y-%m-%d %H:%M:%.S'
	export CREATE_BACKUP_HOURS="12"
fi

export PURGE_BACKUP_DAYS=$(echo "${PURGE_BACKUP_DAYS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${PURGE_BACKUP_DAYS}" ]]; then
	echo "[info] PURGE_BACKUP_DAYS defined as '${PURGE_BACKUP_DAYS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] PURGE_BACKUP_DAYS not defined,(via -e PURGE_BACKUP_DAYS), defaulting to '14'" | ts '%Y-%m-%d %H:%M:%.S'
	export PURGE_BACKUP_DAYS="14"
fi

export ENABLE_WEBUI_CONSOLE=$(echo "${ENABLE_WEBUI_CONSOLE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_WEBUI_CONSOLE}" ]]; then
	echo "[info] ENABLE_WEBUI_CONSOLE defined as '${ENABLE_WEBUI_CONSOLE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] ENABLE_WEBUI_CONSOLE not defined,(via -e ENABLE_WEBUI_CONSOLE), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_WEBUI_CONSOLE="yes"
fi

if [[ "${ENABLE_WEBUI_CONSOLE}" == "yes" ]]; then
	export ENABLE_WEBUI_AUTH=$(echo "${ENABLE_WEBUI_AUTH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${ENABLE_WEBUI_AUTH}" ]]; then
		echo "[info] ENABLE_WEBUI_AUTH defined as '${ENABLE_WEBUI_AUTH}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] ENABLE_WEBUI_AUTH not defined (via -e ENABLE_WEBUI_AUTH), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
		export ENABLE_WEBUI_AUTH="yes"
	fi

	if [[ $ENABLE_WEBUI_AUTH == "yes" ]]; then
		export WEBUI_USER=$(echo "${WEBUI_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${WEBUI_USER}" ]]; then
			echo "[info] WEBUI_USER defined as '${WEBUI_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] WEBUI_USER not defined (via -e WEBUI_USER), defaulting to 'admin'" | ts '%Y-%m-%d %H:%M:%.S'
			export WEBUI_USER="admin"
		fi

		export WEBUI_PASS=$(echo "${WEBUI_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${WEBUI_PASS}" ]]; then
			if [[ "${WEBUI_PASS}" == "minecraft" ]]; then
				echo "[warn] WEBUI_PASS defined as '${WEBUI_PASS}' is weak, please consider using a stronger password" | ts '%Y-%m-%d %H:%M:%.S'
			else
				echo "[info] WEBUI_PASS defined as '${WEBUI_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
			fi
		else
			WEBUI_PASS_file="/config/minecraft/security/WEBUI_PASS"
			if [ ! -f "${WEBUI_PASS_file}" ]; then
				# generate random password for web ui using SHA to hash the date,
				# run through base64, and then output the top 16 characters to a file.
				mkdir -p "/config/minecraft/security" ; chown -R nobody:users "/config/minecraft"
				date +%s | sha256sum | base64 | head -c 16 > "${WEBUI_PASS_file}"
			fi
			echo "[warn] WEBUI_PASS not defined (via -e WEBUI_PASS), using randomised password (password stored in '${WEBUI_PASS_file}')" | ts '%Y-%m-%d %H:%M:%.S'
			export WEBUI_PASS="$(cat ${WEBUI_PASS_file})"
		fi
	fi

	export WEBUI_CONSOLE_TITLE=$(echo "${WEBUI_CONSOLE_TITLE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${WEBUI_CONSOLE_TITLE}" ]]; then
		echo "[info] WEBUI_CONSOLE_TITLE defined as '${WEBUI_CONSOLE_TITLE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[info] WEBUI_CONSOLE_TITLE not defined,(via -e WEBUI_CONSOLE_TITLE), defaulting to 'Minecraft Java'" | ts '%Y-%m-%d %H:%M:%.S'
		export WEBUI_CONSOLE_TITLE="Minecraft Java"
	fi
fi

export CUSTOM_JAR_PATH=$(echo "${CUSTOM_JAR_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${CUSTOM_JAR_PATH}" ]]; then
	echo "[info] CUSTOM_JAR_PATH defined as '${CUSTOM_JAR_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] CUSTOM_JAR_PATH not defined,(via -e CUSTOM_JAR_PATH), defaulting to '/config/minecraft/minecraft_server.jar' (Mojang Minecraft Java)" | ts '%Y-%m-%d %H:%M:%.S'
	export CUSTOM_JAR_PATH="/config/minecraft/minecraft_server.jar"
fi

# get latest java version for package 'jre-openjdk-headless'
latest_java_version=$(pacman -Qi jre-openjdk-headless | grep -P -o -m 1 '^Version\s*: \K.+' | grep -P -o -m 1 '^[0-9]+')

export JAVA_VERSION=$(echo "${JAVA_VERSION}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_VERSION}" ]]; then
	echo "[info] JAVA_VERSION defined as '${JAVA_VERSION}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_VERSION not defined,(via -e JAVA_VERSION), defaulting to Java version 'latest'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_VERSION="latest"
fi

if [[ "${JAVA_VERSION}" == "8" ]]; then
	ln -fs '/usr/lib/jvm/java-8-openjdk/jre/bin/java' '/usr/bin/java'
	archlinux-java set java-8-openjdk/jre
elif [[ "${JAVA_VERSION}" == "11" ]]; then
	ln -fs '/usr/lib/jvm/java-11-openjdk/bin/java' '/usr/bin/java'
	archlinux-java set java-11-openjdk
elif [[ "${JAVA_VERSION}" == "17" ]]; then
	ln -fs '/usr/lib/jvm/java-17-openjdk/bin/java' '/usr/bin/java'
	archlinux-java set java-17-openjdk
elif [[ "${JAVA_VERSION}" == "latest" ]]; then
	ln -fs "/usr/lib/jvm/java-${latest_java_version}-openjdk/bin/java" '/usr/bin/java'
	archlinux-java set java-${latest_java_version}-openjdk
else
	echo "[warn] Java version '${JAVA_VERSION}' not valid, defaulting to Java version 'latest" | ts '%Y-%m-%d %H:%M:%.S'
	ln -fs "/usr/lib/jvm/java-${latest_java_version}-openjdk/bin/java" '/usr/bin/java'
	archlinux-java set java-${latest_java_version}-openjdk
fi

export JAVA_INITIAL_HEAP_SIZE=$(echo "${JAVA_INITIAL_HEAP_SIZE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_INITIAL_HEAP_SIZE}" ]]; then
	echo "[info] JAVA_INITIAL_HEAP_SIZE defined as '${JAVA_INITIAL_HEAP_SIZE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_INITIAL_HEAP_SIZE not defined,(via -e JAVA_INITIAL_HEAP_SIZE), defaulting to '512M'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_INITIAL_HEAP_SIZE="512M"
fi

export JAVA_MAX_HEAP_SIZE=$(echo "${JAVA_MAX_HEAP_SIZE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_MAX_HEAP_SIZE}" ]]; then
	echo "[info] JAVA_MAX_HEAP_SIZE defined as '${JAVA_MAX_HEAP_SIZE}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_MAX_HEAP_SIZE not defined,(via -e JAVA_MAX_HEAP_SIZE), defaulting to '1024M'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_MAX_HEAP_SIZE="1024M"
fi

export JAVA_MAX_THREADS=$(echo "${JAVA_MAX_THREADS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_MAX_THREADS}" ]]; then
	echo "[info] JAVA_MAX_THREADS defined as '${JAVA_MAX_THREADS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_MAX_THREADS not defined,(via -e JAVA_MAX_THREADS), defaulting to '1'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_MAX_THREADS="1"
fi

export STARTUP_CMD=$(echo "${STARTUP_CMD}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${STARTUP_CMD}" ]]; then
	echo "[info] STARTUP_CMD defined as '${STARTUP_CMD}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] STARTUP_CMD not defined (via -e STARTUP_CMD)" | ts '%Y-%m-%d %H:%M:%.S'
fi

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
