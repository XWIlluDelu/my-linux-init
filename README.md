# my-linux-init

Linux 环境一键部署脚本，自动安装并配置 **Zsh** + **Tmux** 及常用工具。

## 一键安装 (标准模式)

最简单的安装方式，直接运行以下命令：

```bash
curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/my-linux-init/main/bootstrap.sh | bash
```

## 覆盖安装 (Overwrite 模式)

如果之前的配置或环境出现问题，希望**清理残留的缓存并重新安装配置**，可以传入 `--overwrite` 参数：

```bash
curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/my-linux-init/main/bootstrap.sh | bash -s -- --overwrite
```

> **注意：** 该模式会删除 `$HOME/.local/share/zinit` 以及清理旧版的 `starship`, `chezmoi`, `fzf` 和相关配置文件，确保获取一个干净的最新环境。

## 传统运行方案 (解决网络下载中断)

如果在运行一键脚本时遇到网络不可靠的问题，也可以手动下载脚本到本地后再运行：

```bash
# 1. 下载脚本
curl -L -o bootstrap.sh "https://raw.githubusercontent.com/XWIlluDelu/my-linux-init/main/bootstrap.sh"

# 2. 赋予执行权限并运行
chmod +x bootstrap.sh
./bootstrap.sh

# (可选) 若需覆盖清理安装，也是在后面加上参数即可：
./bootstrap.sh --overwrite
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
