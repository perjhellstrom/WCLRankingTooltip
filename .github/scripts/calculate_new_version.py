import sys

def parse_version(tag):
    """Parse the semantic version from a git tag."""
    major, minor, patch = map(int, tag.split('.'))
    return major, minor, patch

def calculate_new_version(last_tag, version_type):
    """Calculate the new version number based on the last tag and version bump type."""
    major, minor, patch = parse_version(last_tag)
    
    if version_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif version_type == 'minor':
        minor += 1
        patch = 0
    elif version_type == 'patch':
        patch += 1
    else:
        raise ValueError("Unknown version type. Expected one of: major, minor, patch.")
    
    return f"{major}.{minor}.{patch}"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python calculate_new_version.py <last_tag> <version_type>")
        sys.exit(1)

    last_tag = sys.argv[1]
    version_type = sys.argv[2]

    new_version = calculate_new_version(last_tag, version_type)
    print(new_version)
