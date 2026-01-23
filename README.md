# WPILib Dev Container

A pre-configured Development Container for FRC robot code development. This project automates the creation of a Docker image containing the specific version of the JDK, RoboRIO toolchain, and VS Code extensions required for WPILib.

The container is built automatically when new versions of WPILib are detected.

## Features

* **Base OS:** Ubuntu 24.04 (via Microsoft Dev Containers base)  
* **Java:** WPILib-specific JDK 17 (Eclipse Temurin)  
* **Compiler:** RoboRIO Toolchain (GCC 12.1.0+)  
* **IDE Support:** Pre-installed WPILib VS Code Extension  
* **Automation:** Nightly checks against upstream WPILib repositories to ensure versions match the latest official release.

## Usage

This image is designed to be used with [Github Codespaces](https://github.com/features/codespaces) or the [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) extension.

### devcontainer.json Configuration

Add a [.devcontainer/devcontainer.json](sample-devcontainer.json) file to your robot project with the following configuration. This sets up the environment variables and paths to use the pre-installed tools instead of downloading them locally.

```json
{
    "name": "WPILib 2026",
    "image": "ghcr.io/npmanos/devcontainer_wpilib:2026",
    "customizations": {
        "vscode": {
            "settings": {
                "java.home": "/home/vscode/wpilib/2026/jdk",
                "java.import.gradle.java.home": "/home/vscode/wpilib/2026/jdk",
                "java.configuration.runtimes": [
                    {
                        "name": "JavaSE-17",
                        "path": "/home/vscode/wpilib/2026/jdk",
                        "default": true
                    }
                ],
                "terminal.integrated.env.linux": {
                    "JAVA_HOME": "/home/vscode/wpilib/2026/jdk"
                }
            },
            "extensions": [
                "vscjava.vscode-java-pack",
                "ms-vscode.cpptools-extension-pack"
            ]
        }
    },
    "postCreateCommand": "code --install-extension /home/vscode/wpilib/vscode-wpilib.vsix",
    "remoteUser": "vscode",
    "features": {
        "ghcr.io/stuartleeks/dev-container-features/shell-history:0": {}
    }
}
```

*Note: Ensure the year in the paths (e.g., 2026) matches the WPILib year you are targeting.*

### Gradle Setup

The container includes the necessary compilers. Your build.gradle should function normally, as the JAVA_HOME environment variable is set globally within the container to point to the correct JDK.

## Container Tags

Images are published to the GitHub Container Registry (ghcr.io).

| Tag     | Description                                  | Example                                      |
| :----   | :----                                        | :----                                        |
| latest  | The most recent build of the current season. | ghcr.io/npmanos/devcontainer_wpilib:latest   |
| YEAR    | The latest build for a specific FRC season.  | ghcr.io/npmanos/devcontainer_wpilib:2026     |
| VERSION | A specific WPILib release version.           | ghcr.io/npmanos/devcontainer_wpilib:2026.2.1 |

## Automation & Versioning

This repository uses a Python script ([scripts/update_versions.py]) to scrape version metadata directly from the [WPILib Installer Gradle configuration](https://github.com/wpilibsuite/WPILibInstaller-Avalonia).

- **Daily Check:** A GitHub Action runs daily at 04:00 UTC.  
- **Auto-Update:** If a version mismatch is found, the script updates the .versions file and commits the change.  
- **Auto-Publish:** A commit to the .versions file triggers a build and publish of the new Docker image.

## License

This project is released into the public domain under The Unlicense. See [LICENSE](https://www.google.com/search?q=LICENSE) for details.
