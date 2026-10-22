FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG TARGETARCH
ARG WPILIB_YEAR
ARG VSCODE_WPILIB_VERSION
ARG JDK_TAG

ARG VSCODE_WPILIB_URL=https://github.com/wpilibsuite/vscode-wpilib/releases/download/v${VSCODE_WPILIB_VERSION}/vscode-wpilib-${VSCODE_WPILIB_VERSION}.vsix
ARG JAVA_LSP_ARM_URL
ARG JAVA_LSP_X64_URL


LABEL org.opencontainers.image.source="https://github.com/athenian-robotics/arc-devcontainer"
LABEL org.opencontainers.image.base.name="mcr.microsoft.com/devcontainers/base:ubuntu-24.04"
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
    && JDK_URL="https://api.adoptium.net/v3/binary/version/jdk-$JDK_TAG/linux/$JDK_ARCH/jdk/hotspot/normal/eclipse" \
    # Install JDK
    && wget -nv "${JDK_URL}" -O /tmp/jdk.tar.gz \
    && tar -xzf /tmp/jdk.tar.gz -C /home/vscode/wpilib/${WPILIB_YEAR}/jdk --strip-components=1 \
    && rm /tmp/jdk.tar.gz

# Install VS Code Extension
RUN wget -nv ${VSCODE_WPILIB_URL} -O /home/vscode/extension-artifacts/vscode-wpilib.vsix
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        wget -nv "$JAVA_LSP_ARM_URL" -O /home/vscode/extension-artifacts/redhat-java.vsix; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        wget -nv "$JAVA_LSP_X64_URL" -O /home/vscode/extension-artifacts/redhat-java.vsix; \
    fi

# Fix permissions
RUN sudo chown -R vscode:vscode /home/vscode/wpilib /home/vscode/extension-artifacts

# Environment Setup
ENV JAVA_HOME=/home/vscode/wpilib/${WPILIB_YEAR}/jdk
ENV PATH=${JAVA_HOME}/bin:$PATH:/home/vscode/wpilib/${WPILIB_YEAR}/roborio/bin

CMD [ "/bin/bash" ]