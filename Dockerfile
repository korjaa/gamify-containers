# Use Ubuntu 20.04. There is no stable wine available for Ubuntu 22.04.
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND="noninteractive"

# Enable 32-bit architecture
RUN dpkg --add-architecture i386

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        dbus-x11 \
        pulseaudio \
        x11-xserver-utils \
        apt-transport-https \
        ca-certificates \
        git \
        gosu \
        gpg-agent \
        p7zip \
        software-properties-common \
        tzdata \
        unzip \
        wget \
        zenity \
        gnupg \
        less \
        pciutils \
        stterm \
        htop \
        vim \
        vulkan-utils \
        mesa-utils \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        libvulkan1 \
        libvulkan1:i386 \
        libglx-mesa0 \
        libgl1-mesa-dri \
        xauth \
        jq \
        curl \
        libcanberra-gtk-module \
        libcanberra-gtk3-module

# Nvidia driver
#  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
ARG nvidia_binary_version="515.48.07"
ARG nvidia_binary="NVIDIA-Linux-x86_64-${nvidia_binary_version}.run"
RUN distribution=$(. /etc/os-release; echo $ID$VERSION_ID) \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list
RUN apt update \
    && apt-get install -y --no-install-recommends \
        kmod \
        pkg-config \
        libglvnd-dev \
        nvidia-container-runtime \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q https://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidia_binary_version}/${nvidia_binary} \
    && chmod +x ${nvidia_binary} \
    && ./${nvidia_binary} --accept-license --ui=none --no-kernel-module --no-questions \
    && rm -rf ${nvidia_binary}
ENV VK_ICD_FILENAMES=/etc/vulkan/icd.d/nvidia_icd.json

# Install Wine
RUN \
    export DIST_CODENAME="$(. /etc/os-release; echo $UBUNTU_CODENAME)" \
    && wget -nc -O /usr/share/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -nc -P /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/${DIST_CODENAME}/winehq-${DIST_CODENAME}.sources \
    && apt-get update \
    && apt install winehq-stable --install-recommends  -y \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN curl -Lo /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks

# Lutris
RUN add-apt-repository ppa:lutris-team/lutris && \
    apt update && \
    apt install -y --no-install-recommends \
        lutris && \
    rm -rf /var/lib/apt/lists/*

# Battle.net dependencies
#  https://github.com/lutris/docs/blob/master/Battle.Net.md
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    && apt-get install libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libsqlite3-0:i386 \
    && rm -rf /var/lib/apt/lists/*

RUN apt update \
    && apt install -y --no-install-recommends \
        gdb \
        strace

# Disable some dbus warnings
ENV NO_AT_BRIDGE 1
COPY pulse-client.conf /etc/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
