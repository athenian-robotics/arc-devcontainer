import urllib.request
from pathlib import Path
import json
import re
import os
import sys

def get_content(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode('utf-8')

def parse_groovy_ext_properties(content: str) -> dict[str, str]:
    pattern = r"ext\.([a-zA-Z]+)\s*=\s*['\"]([^'\"]+)['\"]"
    matches = re.findall(pattern, content)
    
    return dict(matches)

def main():
    # 1. Get selected WPILib version; fetch newest if unselected
    wpilib_version = None
    if (len(sys.argv) < 2):
        print("No version provided. Fetching newest WPILib version...")
                
        # Fetch gradle.properties to get the newest WPILib version
        props_url = 'https://raw.githubusercontent.com/wpilibsuite/WPILibInstaller-Avalonia/refs/heads/main/gradle.properties'
        props_content = get_content(props_url)

        wpilib_version_match = re.search(r'gradleRioVersion\s*[:=]\s*([^\s]+)', props_content) # Format: `gradleRioVersion: version`
        if not wpilib_version_match:
            raise ValueError("Could not find gradleRioVersion in gradle.properties")
        wpilib_version = wpilib_version_match.group(1)
        print(f"Using newest WPILib Version {wpilib_version}")
    else:
        wpilib_version = sys.argv[1]
        print(f"Using selected WPILib version {wpilib_version}")

    # 2. Fetch `versions.gradle` using the versioned tag
    print(f"Fetching versions.gradle for tag v{wpilib_version}...")
    versions_url = f'https://raw.githubusercontent.com/wpilibsuite/WPILibInstaller-Avalonia/refs/tags/v{wpilib_version}/scripts/versions.gradle'
    versions_content = get_content(versions_url)
    versions = parse_groovy_ext_properties(versions_content)

    # 3. Parse required versions for packages
    jdk_tag_raw = versions.get('jdkVersion')
    wpilib_year = versions.get('frcYear') or versions.get('wpilibYear')

    # 4. Process variables for Dockerfile compatibility

    # JDK TAG: URL encode the '+' to '%2B' for the download URL
    # e.g., jdk-17.0.12+7 -> jdk-17.0.12%2B7
    jdk_tag_encoded = jdk_tag_raw.replace('+', '%2B')

    # 5. Write to .versions file
    output_lines = [
        f"WPILIB_VERSION={wpilib_version}",
        f"WPILIB_YEAR={wpilib_year}",
        f"JDK_TAG={jdk_tag_encoded}",      
    ]

    with open(version_file, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')
    
    print("Successfully wrote new version to " + str(version_file) + " with contents:")
    print('\n'.join(output_lines))

if __name__ == "__main__":
    main()
