# Testing the dotfiles

The repository has a fast local validation suite and a complete Ubuntu bootstrap test.

## Local checks

Requirements:

- Bash
- GNU Stow
- Optional but recommended: Zsh and ShellCheck

Run:

```bash
./scripts/test.sh
# or
make test
```

The script performs:

1. Bash syntax validation
2. Zsh syntax validation when Zsh is available
3. ShellCheck when installed
4. Installation of every Stow package into an isolated temporary home
5. Ghostty SSH terminfo integration configuration
6. Pi web-access LAN configuration checks
7. Commit-pinned public `pi-fork-agent` package manifest checks
8. Bash startup and shared-function smoke tests

## Complete Ubuntu bootstrap

Requirements:

- Docker
- Docker Compose v2 (`docker compose`)

Run:

```bash
./scripts/test-docker.sh
# or
make test-docker
```

This builds `Dockerfile`, runs the complete Linux bootstrap as an unprivileged sudo-enabled user, verifies every expected installed command and link, and then runs the repository checks in the Ubuntu image.

The test exercises:

- apt package installation, including Zsh and `lsof`
- Linux Neovim, tree-sitter, font, pyenv, and Starship installation
- NVM and latest-LTS Node installation
- OpenCode, Pi, the packages in `PiPackages`, and HerdR installation
- Stow linking and conflict handling
- Pi web-access package installation and LAN configuration
- Public `pi-fork-agent` Git package installation
- Vim plugin installation

The full test downloads external tools and can take several minutes.

## Interactive container

To inspect the resulting Ubuntu environment manually:

```bash
docker compose build ubuntu-test
docker compose run --rm ubuntu-test
```

Inside the container:

```bash
./bootstrap.sh
source ~/.bashrc
command -v node npm opencode pi herdr nvim tree-sitter
nvim --version
pi list
```

Use `-T` for non-interactive automation so installers cannot wait for terminal input:

```bash
docker compose run --rm -T ubuntu-bootstrap-test
```

## Bootstrap modes

For quick Stow-only testing on a machine that already has GNU Stow:

```bash
./bootstrap.sh --stow-only
```

To test user-level installers while avoiding Homebrew or apt changes:

```bash
./bootstrap.sh --skip-packages
```

## Cleanup

```bash
docker compose down --remove-orphans
docker image rm dotfiles-ubuntu-test
```
