FROM binhex/arch-base:latest
LABEL org.opencontainers.image.authors = "binhex"
LABEL org.opencontainers.image.source = "https://github.com/binhex/arch-minecraftserver"

# additional files
##################

# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add install bash script
ADD build/root/*.sh /root/

# get release tag name from build arg
ARG release_tag_name

# add run bash script
ADD run/nobody/*.sh /home/nobody/

# add pre-configured config files for log4j mitigation
ADD config/nobody/ /home/nobody/

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh && \
	/bin/bash /root/install.sh "${release_tag_name}"

# docker settings
#################

# expose port for minecraft
EXPOSE 25565

# expose ipv4 port for minecraft web ui console
EXPOSE 8222/tcp

# Security Patch for CVE-2021-44228
ENV LOG4J_FORMAT_MSG_NO_LOOKUPS=true

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/usr/local/bin/init.sh"]