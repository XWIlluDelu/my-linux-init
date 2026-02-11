# Zsh Configuration (chezmoi)

基于 **chezmoi** 管理的 zsh 配置方案，采用 Starship prompt + zinit 插件管理器，面向通过 SSH 远程开发的 Linux 服务器环境。

## 包含什么

```
~/.zshrc                      ← Zsh 主配置
~/.config/starship.toml       ← Starship prompt 配置
~/.gitconfig                  ← Git 用户信息
~/.config/chezmoi/chezmoi.toml ← chezmoi 自身配置（手动创建，不由 chezmoi 管理）
```

### Zsh 配置 (`.zshrc`)

| 模块 | 说明 |
|------|------|
| **PATH** | `~/.local/bin`、`~/.fzf/bin` |
| **History** | 50000 条记录，去重、共享、即时追加、忽略空格开头命令 |
| **Key bindings** | Emacs 模式，Home/End/Delete/Ctrl+方向键，上下箭头按前缀搜索历史 |
| **Zinit 插件** | fast-syntax-highlighting（语法高亮）、zsh-autosuggestions（自动建议）、zsh-completions（补全）、fzf-tab（fzf 增强 Tab 补全）|
| **补全系统** | 大小写不敏感、模糊匹配、菜单选择、fzf-tab 预览 |
| **别名** | `ll`/`la`/`..`/`...`、`grep --color`、trash-cli 安全删除（`rm`→`trash-put`）、Git 快捷键 |
| **代理开关** | `proxy_on` / `proxy_off` 函数，默认开启 `127.0.0.1:7890`（配合 SSH -R 转发）|
| **杂项** | AUTO_CD、AUTO_PUSHD、拼写纠错、交互式注释 |

### Starship Prompt (`starship.toml`)

- 命令耗时 > 2s 才显示
- 目录截断 3 层，Git 仓库内不截断
- 显示 Git 分支/状态、Python 版本/虚拟环境、非零退出码
- 关闭不需要的模块（AWS、Node.js、Ruby、Rust、Java、Go、Docker 等）

### Git 配置 (`.gitconfig`)

- `user.name = XWIlluDelu`
- `user.email = XWIlluDelu@outlook.com`

## 新机器部署

### 真·一键部署

只需 git 和 curl（脚本会自动安装 zsh 及所有依赖工具）：

```bash
curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/zsh-config/main/bootstrap.sh | bash

> 说明：脚本默认执行后自删除。如需保留，请用：
> 
> `BOOTSTRAP_SELF_DELETE=0 bash -s`（例如：
> `curl -fsLS https://raw.githubusercontent.com/XWIlluDelu/zsh-config/main/bootstrap.sh | BOOTSTRAP_SELF_DELETE=0 bash`）

```

脚本会自动完成：
1. 检查并安装 zsh（如缺失，通过 apt/dnf/pacman）
2. 安装 chezmoi → 拉取本仓库 → 部署配置文件
3. 安装 Starship prompt
4. 安装 fzf（模糊搜索）
5. 安装 trash-cli（安全删除）
6. 切换默认 shell 为 zsh
7. 预下载 zinit 插件

完成后运行 `zsh` 或重新登录即可。

> 注意：切换默认 shell（`chsh`）通常需要输入当前用户密码。
> 脚本会在有 TTY 时弹出密码输入；如果在无 TTY 环境（如某些 CI）执行，请手动运行：
> `chsh -s "$(which zsh)"`.

### 手动分步部署

如果不想用一键脚本，也可以手动操作：

```bash
# 1. 安装 chezmoi 并拉取配置
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:XWIlluDelu/zsh-config.git

# 2. 安装 Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin

# 3. 安装 fzf
sudo apt install fzf  # 或从 GitHub 下载二进制

# 4. 安装 trash-cli
pip install trash-cli  # 或 sudo apt install trash-cli

# 5. 修复 umask（多用户服务器 umask=002 时需要）
mkdir -p ~/.config/chezmoi
echo 'umask = 0o022' > ~/.config/chezmoi/chezmoi.toml
chezmoi apply

# 6. 设置默认 shell 为 zsh
chsh -s "$(which zsh)"

# 7. 打开 zsh（首次会下载插件，约 30 秒）
zsh
```

## 日常使用

### 代理

本配置**默认开启代理**（`127.0.0.1:7890`），适用于通过 SSH -R 转发本机代理到服务器的场景：

```bash
# 本机连接服务器时转发代理端口
ssh -R 7890:127.0.0.1:7890 user@server

# 服务器上手动控制代理
proxy_on     # 开启代理
proxy_off    # 关闭代理
```

如果不使用代理转发，取消 `.zshrc` 中 `proxy_on > /dev/null` 那行即可。

### 更新配置

```bash
# 本机修改了配置文件后，同步到 chezmoi 源目录
chezmoi re-add

# 提交并推送
chezmoi cd && git add -A && git commit -m "update config" && git push

# 在其他机器上拉取更新
chezmoi update
```

### 常用别名速查

| 别名 | 命令 | 说明 |
|------|------|------|
| `ll` | `ls -alFh` | 详细列表 |
| `la` | `ls -A` | 显示隐藏文件 |
| `..` | `cd ..` | 上一级 |
| `...` | `cd ../..` | 上两级 |
| `rm` | `trash-put` | 安全删除到回收站 |
| `tl` | `trash-list` | 查看回收站 |
| `trestore` | `trash-restore` | 恢复文件 |
| `tempty` | `trash-empty` | 清空回收站 |
| `gs` | `git status` | |
| `ga` | `git add` | |
| `gc` | `git commit` | |
| `gp` | `git push` | |
| `gl` | `git log --oneline --graph` | 最近 20 条 |
| `gd` | `git diff` | |

## 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| 配置管理 | chezmoi | 一键迁移、模板支持、单二进制零依赖 |
| 插件管理 | zinit | Turbo mode 延迟加载，启动速度比 oh-my-zsh 快 5-8 倍 |
| Prompt | Starship | Rust 编写高性能、跨 shell、TOML 配置简洁 |
| 语法高亮 | fast-syntax-highlighting | 比 zsh-syntax-highlighting 性能更好 |
| Tab 补全 | fzf-tab | 用 fzf 模糊搜索替代默认补全菜单 |
