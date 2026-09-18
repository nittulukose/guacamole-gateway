FROM ubuntu:22.04

ARG NPA_USERNAME=npa-desktop
ARG NPA_PASSWORD=NpaPass123!
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xrdp xfce4 xfce4-goodies dbus-x11 sudo && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ${NPA_USERNAME} && \
    echo "${NPA_USERNAME}:${NPA_PASSWORD}" | chpasswd && \
    echo "xfce4-session" > /home/${NPA_USERNAME}/.xsession && \
    chown ${NPA_USERNAME}:${NPA_USERNAME} /home/${NPA_USERNAME}/.xsession && \
    adduser xrdp ssl-cert

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
