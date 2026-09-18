FROM ubuntu:22.04

ARG NPA_USERNAME=npa-svc
ARG NPA_PASSWORD=NpaPass123!

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server sudo && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

# NPA (Non-Personal Account): the fixed local account Guacamole uses to
# log into this box. It has nothing to do with the LDAP identity of the
# human who opened the session in the portal.
RUN useradd -m -s /bin/bash ${NPA_USERNAME} && \
    echo "${NPA_USERNAME}:${NPA_PASSWORD}" | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
