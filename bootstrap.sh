#!/usr/bin/env bash
# =============================================================================
#  Linux 环境一键部署脚本 (Zsh + Tmux)
#  用法: curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/my-linux-init/main/bootstrap.sh | bash
# =============================================================================
set -euo pipefail

# 设置默认代理
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
export all_proxy="socks5://127.0.0.1:7897"

# 解析命令行参数
OVERWRITE=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --overwrite|-f)
      OVERWRITE=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $*"; }
error() { echo -e "${RED}[xx]${NC} $*"; exit 1; }

get_login_shell() {
    local user="$1"
    local login_shell
    login_shell="$(getent passwd "$user" 2>/dev/null | cut -d: -f7 || true)"
    if [[ -z "$login_shell" ]]; then
        login_shell="$(awk -F: -v u="$user" '$1 == u { print $7 }' /etc/passwd 2>/dev/null || true)"
    fi
    printf '%s' "$login_shell"
}

command -v git  >/dev/null 2>&1 || error "git missing: sudo apt install git"
command -v curl >/dev/null 2>&1 || error "curl missing: sudo apt install curl"

if ! command -v zsh >/dev/null 2>&1; then
    warn "zsh not found, installing..."
    if   command -v apt    >/dev/null 2>&1; then sudo apt update && sudo apt install -y zsh
    elif command -v dnf    >/dev/null 2>&1; then sudo dnf install -y zsh
    elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm zsh
    else error "Cannot auto-install zsh"; fi
    info "zsh installed"
fi

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if [[ "$OVERWRITE" -eq 1 ]]; then
    info "Overwrite mode enabled. Cleaning up old configs and binaries..."
    rm -rf "$HOME/.local/share/zinit"
    rm -rf "$HOME/.local/share/chezmoi"
    rm -rf "$HOME/.config/chezmoi"
    rm -f "$HOME/.local/bin/starship" "$HOME/.local/bin/fzf" "$HOME/.local/bin/chezmoi"
fi

# 1. chezmoi
if ! command -v chezmoi >/dev/null 2>&1; then
    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
info "chezmoi $(chezmoi --version | head -1)"

# 2. chezmoi init + apply
info "Pulling config..."
chezmoi init --apply git@github.com:XWIlluDelu/my-linux-init.git
mkdir -p "$HOME/.config/chezmoi"
if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
    printf 'umask = 0o022\n' > "$HOME/.config/chezmoi/chezmoi.toml"
    info "chezmoi umask config created"
fi
chezmoi apply
info "Config deployed"

# 3. Starship
if ! command -v starship >/dev/null 2>&1; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi
info "Starship $(starship --version | head -1)"

# 4. fzf
if ! command -v fzf >/dev/null 2>&1; then
    info "Installing fzf..."
    FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [[ -n "$FZF_VERSION" ]]; then
        curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION#v}-linux_amd64.tar.gz"
        tar xzf /tmp/fzf.tar.gz -C "$HOME/.local/bin/" fzf
        rm -f /tmp/fzf.tar.gz
        info "fzf ${FZF_VERSION}"
    else
        warn "fzf download failed (proxy?). Install later: sudo apt install fzf"
    fi
else
    info "fzf $(fzf --version | head -1)"
fi

# 5. trash-cli
if ! command -v trash-put >/dev/null 2>&1; then
    info "Installing trash-cli..."
    if   command -v pip >/dev/null 2>&1; then pip install --user trash-cli 2>/dev/null || sudo apt install -y trash-cli 2>/dev/null || warn "trash-cli failed"
    elif command -v apt >/dev/null 2>&1; then sudo apt install -y trash-cli || warn "trash-cli failed"
    else warn "trash-cli not available"; fi
else
    info "trash-cli exists"
fi

# 6. tmux
if ! command -v tmux >/dev/null 2>&1; then
    info "Installing tmux..."
    if   command -v apt    >/dev/null 2>&1; then sudo apt install -y tmux
    elif command -v dnf    >/dev/null 2>&1; then sudo dnf install -y tmux
    elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm tmux
    else warn "Cannot auto-install tmux"; fi
    info "tmux installed"
else
    info "tmux $(tmux -V)"
fi

# 7. default shell
ZSH_PATH="$(command -v zsh)"
LOGIN_USER="${SUDO_USER:-${USER:-$(id -un)}}"
CURRENT_LOGIN_SHELL="$(get_login_shell "$LOGIN_USER")"

if [[ "$CURRENT_LOGIN_SHELL" != "$ZSH_PATH" ]]; then
    warn "Switching default shell to zsh for $LOGIN_USER..."
    if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
        warn "$ZSH_PATH is not in /etc/shells, chsh may fail"
    fi

    CHSH_OK=0
    if [[ "$(id -u)" -eq 0 ]]; then
        chsh -s "$ZSH_PATH" "$LOGIN_USER" >/dev/null 2>&1 && CHSH_OK=1
    else
        # In `curl ... | bash`, stdin is usually a pipe; use /dev/tty for password prompt.
        if exec 3<>/dev/tty 2>/dev/null; then
            warn "Password prompt may appear for chsh..."
            chsh -s "$ZSH_PATH" "$LOGIN_USER" <&3 >&3 2>&3 && CHSH_OK=1
            exec 3>&-
        fi
        if [[ -e /proc/self/fd/3 ]]; then
            exec 3>&- || true
        fi
        if [[ "$CHSH_OK" -ne 1 ]] && sudo -n true 2>/dev/null; then
            sudo chsh -s "$ZSH_PATH" "$LOGIN_USER" >/dev/null 2>&1 && CHSH_OK=1
        fi
    fi

    NEW_LOGIN_SHELL="$(get_login_shell "$LOGIN_USER")"
    if [[ "$NEW_LOGIN_SHELL" == "$ZSH_PATH" ]]; then
        info "Default shell updated: $ZSH_PATH"
    else
        warn "Default shell change was not completed"
        warn "Run manually: chsh -s \"$ZSH_PATH\" \"$LOGIN_USER\""
    fi
else
    info "Default shell already zsh"
fi

# 8. preload zinit plugins
info "Preloading zinit plugins (~30s)..."
zsh -i -c 'exit' 2>/dev/null || true
info "Done"

echo ""
echo -e "${GREEN}======== Deploy complete! ========${NC}"
echo "  Run zsh or re-login to start."
echo "  tmux: tmux new -s main"
echo "  Proxy: proxy_on / proxy_off (default ON @ 127.0.0.1:7897)"

# ---------------------------------------------------------------------------
#  Self-destruct (可关闭：BOOTSTRAP_SELF_DELETE=0)
# ---------------------------------------------------------------------------
if [[ "${BOOTSTRAP_SELF_DELETE:-1}" = "1" ]]; then
    script_path="${BASH_SOURCE[0]:-$0}"
    if [[ -f "$script_path" ]]; then
        rm -f -- "$script_path" || true
    fi
fi
