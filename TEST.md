# Testing Dotfiles with Docker

This document provides instructions for testing the cross-platform dotfiles setup using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose (usually included with Docker Desktop)

## Quick Test

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and run the test container
docker-compose run ubuntu-test

# Once inside the container, test the bootstrap script
./bootstrap.sh

# Test the installation
source ~/.zshrc
# or
source ~/.bashrc
```

### Option 2: Clean Ubuntu Environment

```bash
# Run a fresh Ubuntu container each time
docker-compose run ubuntu-clean

# Inside the container, run as testuser:
su - testuser
cd /home/testuser/dotfiles
./bootstrap.sh
```

### Option 3: Manual Docker Build

```bash
# Build the Docker image
docker build -t dotfiles-test .

# Run the container
docker run -it --rm dotfiles-test

# Inside the container, test the bootstrap script
./bootstrap.sh
```

## Testing Steps

1. **Run the bootstrap script:**
   ```bash
   ./bootstrap.sh
   ```

2. **Verify OS detection:**
   The script should detect "linux" and use apt-get for installations.

3. **Test installed tools:**
   ```bash
   # Check if tools are installed
   which starship
   which fzf
   which eza
   which bat
   which fd
   which rg
   
   # Check if symlinks work (Linux-specific)
   ls -la ~/.local/bin/
   ```

4. **Test shell functions:**
   ```bash
   # Source the shell configuration
   source ~/.zshrc  # or ~/.bashrc
   
   # Test functions
   myip
   mkcd test-dir
   up
   killport 8080
   serve 3000 &
   killport 3000
   ```

5. **Test aliases:**
   ```bash
   # Test navigation aliases
   ...
   cd -
   
   # Test git alias
   g status
   
   # Test enhanced commands (if available)
   ls  # should use eza if installed
   cat README.md  # should use bat if installed
   ```

6. **Test Starship prompt:**
   ```bash
   # The prompt should show the Starship design
   # Navigate to a git repo to test git integration
   cd /tmp
   git init
   # Prompt should show git branch
   ```

## Troubleshooting

### Font Issues
- Fonts won't display properly in terminal without GUI
- This is expected in Docker containers

### Permission Issues
- The container runs as `testuser` with sudo privileges
- Password is `testuser` if needed

### Network Issues
- If downloads fail, check your internet connection
- Some corporate networks may block certain URLs

## Cleanup

```bash
# Remove containers
docker-compose down

# Remove built image
docker rmi dotfiles-test

# Clean up volumes (if any)
docker system prune
```

## Testing Different Ubuntu Versions

You can test against different Ubuntu versions by modifying the Dockerfile:

```dockerfile
# Change the base image
FROM ubuntu:20.04  # or ubuntu:18.04, ubuntu:24.04
```

Then rebuild:
```bash
docker-compose build ubuntu-test
```

## Expected Results

After successful installation, you should see:
- ✅ All development tools installed
- ✅ Starship prompt active
- ✅ Modern CLI tools working (with symlinks where needed)
- ✅ Shell functions operational
- ✅ Cross-platform compatibility confirmed

## Notes

- The Docker environment simulates a fresh Ubuntu installation
- Some GUI features (like Finder aliases) won't work in Docker
- Font rendering may not be perfect without a GUI terminal
- This tests the Linux installation path of the bootstrap script