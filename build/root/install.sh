#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# pacman packages
####

# define pacman packages
pacman_packages="jre8-openjdk-headless screen"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="minecraft-server"

# call aur install script (arch user repo)
source aur.sh

# config java minecraft
####

# copy config file containing env vars, sourced in from /usr/bin/minecraftd
cp /home/nobody/minecraft /etc/conf.d/minecraft

# container perms
####

# define comma separated list of paths 
install_paths="/etc/conf.d,/srv,/home/nobody"

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

export MAX_BACKUPS=$(echo "${MAX_BACKUPS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${MAX_BACKUPS}" ]]; then
	echo "[info] MAX_BACKUPS defined as '${MAX_BACKUPS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] MAX_BACKUPS not defined,(via -e MAX_BACKUPS), defaulting to '10'" | ts '%Y-%m-%d %H:%M:%.S'
	export MAX_BACKUPS="10"
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
	export MAX_BACKUPS="1024M"
fi

export JAVA_MAX_THREADS=$(echo "${JAVA_MAX_THREADS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_MAX_THREADS}" ]]; then
	echo "[info] JAVA_MAX_THREADS defined as '${JAVA_MAX_THREADS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_MAX_THREADS not defined,(via -e JAVA_MAX_THREADS), defaulting to '1'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_MAX_THREADS="1"
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
