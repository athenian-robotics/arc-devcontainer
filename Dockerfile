FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL org.opencontainers.image.source="https://github.com/npmanos/wpilib-container"
LABEL org.opencontainers.image.base.name="mcr.microsoft.com/devcontainers/base:ubuntu-24.04"


# Argument for the WPILib Year
ARG WPILIB_YEAR

# --- ARTIFACT VERSIONS ---
# Toolchain
ARG GCC_VERSION
ARG TOOLCHAIN_VERSION
ARG TOOLCHAIN_FILE=cortexa9_vfpv3-roborio-academic-2025-x86_64-linux-gnu-Toolchain-${GCC_VERSION}.tgz

# VS Code Extension
ARG VSCODE_WPILIB_VERSION
ARG VSCODE_WPILIB_URL=https://github.com/wpilibsuite/vscode-wpilib/releases/download/v${VSCODE_WPILIB_VERSION}/vscode-wpilib-${VSCODE_WPILIB_VERSION}.vsix

LABEL org.opencontainers.image.version="$VSCODE_WPILIB_VERSION"

# WPILib JDK (Eclipse Temurin 17)
# Using official Adoptium binaries as the source
ARG JDK_TAG
ARG JDK_TAG_CLEAN
ARG JDK_FILE=OpenJDK17U-jdk_x64_linux_hotspot_${JDK_TAG_CLEAN}.tar.gz
ARG JDK_URL=https://github.com/adoptium/temurin17-binaries/releases/download/${JDK_TAG}/${JDK_FILE}

ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies (Removed system openjdk-17-jdk)
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gdb \
    wget \
    curl \
    git \
    unzip \
    sudo \
    python3 \
    python3-pip \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /home/vscode

# Create WPILib directory structure
RUN mkdir -p /home/vscode/wpilib/${WPILIB_YEAR}/roborio \
    && mkdir -p /home/vscode/wpilib/${WPILIB_YEAR}/tools \
    && mkdir -p /home/vscode/wpilib/${WPILIB_YEAR}/maven \
    && mkdir -p /home/vscode/wpilib/${WPILIB_YEAR}/jdk

# 1. Install WPILib JDK
# We strip the first component because the tarball usually contains a root folder like 'jdk-17.0.12+7'
RUN wget -q ${JDK_URL} -O /tmp/jdk.tar.gz \
    && tar -xzf /tmp/jdk.tar.gz -C /home/vscode/wpilib/${WPILIB_YEAR}/jdk --strip-components=1 \
    && rm /tmp/jdk.tar.gz

# 2. Install RoboRIO Toolchain
RUN cd /tmp \
    && wget -q https://github.com/wpilibsuite/opensdk/releases/download/${TOOLCHAIN_VERSION}/${TOOLCHAIN_FILE} \
    && tar -xzf ${TOOLCHAIN_FILE} -C /home/vscode/wpilib/${WPILIB_YEAR}/roborio \
    && rm ${TOOLCHAIN_FILE}

# 3. Bake the WPILib VS Code Extension
RUN wget -q ${VSCODE_WPILIB_URL} -O /home/vscode/wpilib/vscode-wpilib.vsix

# Fix permissions
RUN sudo chown -R vscode:vscode /home/vscode/wpilib

# Environment Setup
# Point JAVA_HOME to the WPILib JDK
ENV JAVA_HOME=/home/vscode/wpilib/${WPILIB_YEAR}/jdk
ENV PATH=${JAVA_HOME}/bin:$PATH:/home/vscode/wpilib/${WPILIB_YEAR}/roborio/bin

CMD [ "/bin/bash" ]