FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

LABEL org.opencontainers.image.source="https://github.com/npmanos/wpilib-container"
LABEL org.opencontainers.image.base.name="mcr.microsoft.com/devcontainers/base:ubuntu-24.04"

ARG TARGETARCH
ARG WPILIB_YEAR
ARG GCC_VERSION
ARG TOOLCHAIN_VERSION
ARG VSCODE_WPILIB_VERSION
ARG VSCODE_WPILIB_URL=https://github.com/wpilibsuite/vscode-wpilib/releases/download/v${VSCODE_WPILIB_VERSION}/vscode-wpilib-${VSCODE_WPILIB_VERSION}.vsix
ARG JDK_TAG
ARG JDK_TAG_CLEAN

LABEL org.opencontainers.image.version="$VSCODE_WPILIB_VERSION"

ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
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

# Install WPILib JDK and Toolchain based on architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        JDK_ARCH="x64"; \
        TOOLCHAIN_ARCH="x86_64-linux-gnu"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        JDK_ARCH="aarch64"; \
        TOOLCHAIN_ARCH="aarch64-bullseye-linux-gnu"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi \
    && echo "Downloading for architecture: $TARGETARCH" \
    && JDK_FILE="OpenJDK17U-jdk_${JDK_ARCH}_linux_hotspot_${JDK_TAG_CLEAN}.tar.gz" \
    && JDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${JDK_TAG}/${JDK_FILE}" \
    && TOOLCHAIN_FILE="cortexa9_vfpv3-roborio-academic-${TOOLCHAIN_VERSION%%.*}-${TOOLCHAIN_ARCH}-Toolchain-${GCC_VERSION}.tgz" \
    && TOOLCHAIN_URL="https://github.com/wpilibsuite/opensdk/releases/download/${TOOLCHAIN_VERSION}/${TOOLCHAIN_FILE}" \
    # Install JDK
    && wget -q "${JDK_URL}" -O /tmp/jdk.tar.gz \
    && tar -xzf /tmp/jdk.tar.gz -C /home/vscode/wpilib/${WPILIB_YEAR}/jdk --strip-components=1 \
    && rm /tmp/jdk.tar.gz \
    # Install Toolchain
    && cd /tmp \
    && wget -q "${TOOLCHAIN_URL}" \
    && tar -xzf "${TOOLCHAIN_FILE}" -C /home/vscode/wpilib/${WPILIB_YEAR}/roborio \
    && rm "${TOOLCHAIN_FILE}"

# Install VS Code Extension
RUN wget -q ${VSCODE_WPILIB_URL} -O /home/vscode/wpilib/vscode-wpilib.vsix

# Fix permissions
RUN sudo chown -R vscode:vscode /home/vscode/wpilib

# Environment Setup
ENV JAVA_HOME=/home/vscode/wpilib/${WPILIB_YEAR}/jdk
ENV PATH=${JAVA_HOME}/bin:$PATH:/home/vscode/wpilib/${WPILIB_YEAR}/roborio/bin

CMD [ "/bin/bash" ]