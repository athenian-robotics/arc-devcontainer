import urllib.request
import json
import re
import os

def get_content(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode('utf-8')

def parse_groovy_ext_properties(content: str) -> dict[str, str]:
    pattern = r"ext\.([a-zA-Z]+)\s*=\s*['\"]([^'\"]+)['\"]"
    matches = re.findall(pattern, content)
    
    return dict(matches)

# Fetch latest version of redhat.java LSP extension
# We install this here rather than in the .devcontainer.json so we can get the platform-specific extension
#   version, rather than the 'universal' version. This lets us use a bundled JRE and pin the extension version.
def redhat_java_vsix(arch: str) -> str:
    url = "https://open-vsx.org/api/redhat/java"
    metadata_str = get_content(url)
    metadata = json.loads(metadata_str)

    return metadata['downloads'][arch]
    

def main():
    print("Fetching WPILib version...")
    # 1. Fetch gradle.properties to get the main WPILib version
    props_url = 'https://raw.githubusercontent.com/wpilibsuite/WPILibInstaller-Avalonia/refs/heads/main/gradle.properties'
    props_content = get_content(props_url)
    
    wpilib_version_match = re.search(r'gradleRioVersion\s*[:=]\s*([^\s]+)', props_content)
    if not wpilib_version_match:
        raise ValueError("Could not find gradleRioVersion in gradle.properties")
    wpilib_version = wpilib_version_match.group(1)
    print(f"Detected WPILib Version: {wpilib_version}")

    # 2. Fetch `versions.gradle` using the tag
    print(f"Fetching versions.gradle for tag v{wpilib_version}...")
    versions_url = f'https://raw.githubusercontent.com/wpilibsuite/WPILibInstaller-Avalonia/refs/tags/v{wpilib_version}/scripts/versions.gradle'
    versions_content = get_content(versions_url)
    versions = parse_groovy_ext_properties(versions_content)

    # 3. Parse required variables
    jdk_tag_raw = versions.get('jdkVersion')
    wpilib_year = versions.get('frcYear') or versions.get('wpilibYear')

    # 4. Process variables for Dockerfile compatibility

    # JDK TAG: URL encode the '+' to '%2B' for the download URL
    # e.g., jdk-17.0.12+7 -> jdk-17.0.12%2B7
    jdk_tag_encoded = jdk_tag_raw.replace('+', '%2B')

    # 5. Fetch download URL for extension redhat.java
    redhat_java_x64 = redhat_java_vsix('linux-x64')
    redhat_java_arm = redhat_java_vsix('linux-arm64')


    # 6. Write to .versions file
    output_lines = [
        f"VSCODE_WPILIB_VERSION={wpilib_version}",
        f"WPILIB_VERSION={wpilib_version}",
        f"WPILIB_YEAR={wpilib_year}",
        f"JDK_TAG={jdk_tag_encoded}",
        f"JAVA_LSP_ARM_URL={redhat_java_arm}",
        f"JAVA_LSP_X64_URL={redhat_java_x64}"        
    ]

    with open('.versions', 'w') as f:
        f.write('\n'.join(output_lines) + '\n')
    
    print("Successfully updated .versions file:\n")
    print('\n'.join(output_lines))

if __name__ == "__main__":
    main()
