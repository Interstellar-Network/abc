################################################################################
# (from the PROJECT_SOURCE_DIR)
# podman build -f tests/deb/test_deb_exe.dockerfile -t abc:dev .
# podman run -it --rm abc:dev

FROM ubuntu:20.04 as builder

WORKDIR /home/root/

COPY ./build/abc-0.1.1-Linux.deb /home/root/abc.deb

# DEBIAN_FRONTEND needed to stop prompt for timezone
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y /home/root/abc.deb && \
    rm -rf /var/lib/apt/lists/* && \
    rm /home/root/abc.deb

ENTRYPOINT  ["/usr/bin/abc"]