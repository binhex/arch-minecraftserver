FROM binhex/arch-base:latest
LABEL org.opencontainers.image.authors="binhex"
LABEL org.opencontainers.image.source="https://github.com/binhex/arch-minecraftserver"

# release tag name from buildx arg
ARG RELEASETAG

# arch from buildx --platform, e.g. amd64
ARG TARGETARCH

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add install bash script
ADD build/root/*.sh /root/

# add run bash script
ADD run/nobody/*.sh /home/nobody/

# add pre-configured config files for log4j mitigation
ADD config/nobody/ /home/nobody/

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh && \
	/bin/bash /root/install.sh "${RELEASETAG}" "${TARGETARCH}"

# docker settings
#################

# Security Patch for CVE-2021-44228
ENV LOG4J_FORMAT_MSG_NO_LOOKUPS=true

# healthcheck
#############

# ensure internet connectivity, used primarily when sharing network with other conainers
HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl -s https://github.com &>/dev/null || kill 1

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "init.sh"]