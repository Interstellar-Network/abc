################################################################################
# - start with: tests/deb/0_build.dockerfile
# - (from the PROJECT_SOURCE_DIR)
# - podman build -f tests/deb/1_test_deb_exe.dockerfile -t abc:dev .
# - podman run -it --rm abc:dev
# - Then go check tests/deb/2_test_deb_lib.dockerfile

# TO MATCH CI and Rust base image:
# - SHOULD use a ubuntu for the "builder" part
# - SHOULD use a debian part for the final image
#
# That way we SHOULD be able to catch eg
#   The following packages have unmet dependencies:
#   abc : Depends: libstdc++6 (>= 11) but 10.2.1-6 is to be installed
FROM ubuntu:22.04 as builder

WORKDIR /home/root/

COPY --from=abc_build:dev /home/root/abc.deb /home/root/abc.deb

# DEBIAN_FRONTEND needed to stop prompt for timezone
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y /home/root/abc.deb && \
    rm -rf /var/lib/apt/lists/* && \
    rm /home/root/abc.deb

ENTRYPOINT  ["/usr/bin/abc"]