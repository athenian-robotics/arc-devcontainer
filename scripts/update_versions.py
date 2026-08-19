import urllib.request
import re
import os

def get_content(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode('utf-8')

def parse_groovy_ext_properties(content: str) -> dict[str, str]:
    pattern = r"ext\.([a-zA-Z]+)\s*=\s*['\"]([^'\"]+)['\"]"
    matches = re.findall(pattern, content)
    
    return dict(matches)

def main():
    print("Fetching WPILib version...")
    # 1. Fetch gradle.properties to get the main WPILib version
    props_url = 'https://raw.githubusercontent.com/wpilibsuite/WPILibInstaller-Avalonia/refs/heads/main/gradle.properties'
    props_content = get_content(props_url)
    
    # Parse gradleRioVersion: 2026.2.1 (Handles : or = separators)
    # This maps to VSCODE_WPILIB_VERSION in the Dockerfile
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
    gcc_version = versions.get('gccVersion')
    toolchain_version = versions.get('toolchainGitTag')
    jdk_tag_raw = versions.get('jdkVersion') # e.g., jdk-17.0.12+7
    wpilib_year = versions.get('frcYear') or versions.get('wpilibYear')

    # 4. Process variables for Dockerfile compatibility

    # JDK TAG: URL encode the '+' to '%2B' for the download URL
    # e.g., jdk-17.0.12+7 -> jdk-17.0.12%2B7
    jdk_tag_encoded = jdk_tag_raw.replace('+', '%2B')

    # JDK FILE: Construct the tar.gz filename
    # Pattern: jdk-17.0.12+7 -> OpenJDK17U-jdk_x64_linux_hotspot_17.0.12_7.tar.gz
    # Remove 'jdk-' prefix and replace '+' with '_'
    jdk_ver_clean = jdk_tag_raw.replace('jdk-', '').replace('+', '_')
    # jdk_file = f"OpenJDK17U-jdk_x64_linux_hotspot_{jdk_ver_clean}.tar.gz"

    # TOOLCHAIN FILE: Construct the filename
    # Pattern: cortexa9_vfpv3-roborio-academic-{YEAR}-x86_64-linux-gnu-Toolchain-{GCC}.tgz
    # toolchain_file = f"cortexa9_vfpv3-roborio-academic-{wpilib_year}-x86_64-linux-gnu-Toolchain-{gcc_version}.tgz"

    # 5. Write to .versions file
    output_lines = [
        f"VSCODE_WPILIB_VERSION={wpilib_version}",
        f"WPILIB_VERSION={wpilib_version}",
        f"WPILIB_YEAR={wpilib_year}",
        f"GCC_VERSION={gcc_version}",
        f"TOOLCHAIN_VERSION={toolchain_version}",
        # f"TOOLCHAIN_FILE={toolchain_file}",
        f"JDK_TAG={jdk_tag_encoded}",
        f"JDK_TAG_CLEAN={jdk_ver_clean}"
    ]

    with open('.versions', 'w') as f:
        f.write('\n'.join(output_lines) + '\n')
    
    print("Successfully updated .versions file:\n")
    print('\n'.join(output_lines))

if __name__ == "__main__":
    main()
