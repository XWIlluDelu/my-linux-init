# my-linux-init

Linux 环境一键部署脚本，自动安装并配置 **Zsh** + **Tmux** 及常用工具。

## 一键安装

```bash
curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/my-linux-init/main/bootstrap.sh | bash
```

## 自动部署内容

| 工具 | 说明 |
|---|---|
| **Zsh** | 安装并设为默认 shell |
| **chezmoi** | dotfiles 管理，自动拉取并应用配置 |
| **Starship** | 跨 shell 提示符 |
| **fzf** | 模糊搜索 + Tab 补全增强 |
| **trash-cli** | 安全删除（替代 rm） |
| **tmux** | 终端复用器，附带开箱即用配置 |

## 配置文件

- `dot_zshrc` → `~/.zshrc` — Zsh 配置（zinit 插件、别名、代理切换等）
- `dot_tmux.conf` → `~/.tmux.conf` — Tmux 配置（true color、鼠标、Ctrl+a 前缀、直觉分屏等）
- `dot_config/starship.toml` → `~/.config/starship.toml` — Starship 提示符配置
- `dot_gitconfig` → `~/.gitconfig` — Git 基础配置

## 要求

- Linux (Debian/Ubuntu, Fedora, Arch)
- `git` 和 `curl` 已安装
