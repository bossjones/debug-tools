# debug-tools
Comprehensive collection of debugging and utility scripts for Linux systems, development environments, and system administration.

## Script Reference

### 🚀 Installation Scripts
| Script | Description |
|--------|-------------|
| install-uv.sh | Install uv Python package manager with automatic Python 3.12 installation |
| install-ripgrep.sh | Install ripgrep (fast grep alternative) with cross-platform support |
| install-asdf.sh | Install asdf version manager for multiple programming languages |
| install-cheat.sh | Install cheat command-line tool with community cheatsheet integration |
| install-ctop.sh | Install ctop container monitoring tool |
| install-docker.sh | Install Docker with multi-platform support (amd64, Darwin, armhf) |
| install-docker2.sh | Alternative Docker installation method |
| install-filebrowser.sh | Install filebrowser web application |
| install-fnm.sh | Install Fast Node Manager (fnm) |
| install-fonts.sh | Install system fonts |
| install-fpp.sh | Install Facebook PathPicker |
| install-fx.sh | Install fx JSON viewer and processor |
| install-fzf.sh | Install fzf fuzzy finder |
| install-fzf-utils-tmux.sh | Install fzf utilities for tmux integration |
| install-go.sh | Install Go programming language (multi-platform) |
| install-goenv.sh | Install goenv Go version manager |
| install-goss.sh | Install goss server testing tool |
| install-grv.sh | Install grv Git repository viewer |
| install-jid.sh | Install jid JSON incremental digger |
| install-kubebox.sh | Install kubebox Kubernetes dashboard |
| install-kubetail | Install kubetail Kubernetes log viewer |
| install-lunarvim.sh | Install LunarVim IDE configuration |
| install-neovim-config.sh | Install Neovim with custom configuration |
| install-nerdfonts.sh | Install Nerd Fonts for terminal enhancement |
| install-node.sh | Install Node.js runtime |
| install-opencv-deps.sh | Install OpenCV development dependencies |
| install-peco.sh | Install peco interactive filtering tool |
| install-pip3.sh | Install Python 3 and pip package manager |
| install-powerline-fonts.sh | Install Powerline fonts for status bars |
| install-pyenv.sh | Install pyenv Python version manager |
| install-rbenv.sh | Install rbenv Ruby version manager |
| install-systemtap | Install SystemTap dynamic tracing framework |
| install-tmux.sh | Install tmux terminal multiplexer |
| install-vim.sh | Install Vim text editor |
| install-vnctiger.sh | Install TigerVNC viewer |
| install-zsh-pure.sh | Install Pure zsh theme |

### 📊 System Monitoring & Diagnostics
| Script | Description |
|--------|-------------|
| smart_boot_check.sh | Comprehensive SMART disk health diagnostics for Proxmox systems |
| netdata_config_info.sh | Collect system info for Netdata monitoring configuration |
| so_audit.sh | Security Onion comprehensive system audit and information collector |
| health-monitor.sh | Continuous system health monitoring script |
| microbench_ubuntu.sh | System microbenchmarking suite for Ubuntu |
| memory-available.sh | Check available system memory |
| mem | Display memory usage in readable format |
| get-mem | Get detailed memory information |
| ps-cpu | Show processes sorted by CPU usage |
| ps-mem | Show processes sorted by memory usage |
| perf-record-and-report | Linux perf recording and reporting tool |
| perf-top-kubelet | Performance monitoring specifically for kubelet |
| trace-cpu-perf | CPU performance tracing utility |
| softnet.sh | Network softirq monitoring and analysis |
| check-kernel-bcc | Verify kernel configuration for BCC tools |
| check-inotify-watches | Check inotify watch limits |
| check-all-mtu.sh | Verify MTU settings across network interfaces |
| check_netdev | Network device diagnostic tool |
| lsof-fd-check | Check file descriptor usage for processes |
| lsof-fd-check-all | Check file descriptors across all processes |

### 🐳 Docker Management
| Script | Description |
|--------|-------------|
| docker-check-config.sh | Comprehensive Docker configuration validator |
| get-all-docker-logs | Retrieve logs from all Docker containers |
| get-all-docker-debug-logs | Get debug-level logs from Docker containers |
| get-docker-ps-by-name | Find Docker processes by container name |
| setup-docker-gc-cron | Setup Docker garbage collection cron job |
| wrapper-docker-gc | Docker garbage collection wrapper script |
| install-docker-prune-systemd | Install Docker pruning systemd service |

### ☸️ Kubernetes Management
| Script | Description |
|--------|-------------|
| get-kubeadm-config.sh | Extract kubeadm configuration from cluster |
| upgrade-kubelet.sh | Upgrade kubelet to newer version |
| downgrade-kube | Downgrade Kubernetes components |
| hold-kube | Hold Kubernetes packages to prevent updates |
| unhold-kube | Remove holds from Kubernetes packages |
| my-kubeadm-config.yml | Sample kubeadm cluster configuration |

### 🔧 System Configuration & Fixes
| Script | Description |
|--------|-------------|
| create-non-root-user.sh | Create non-root user with sudo privileges and custom groups |
| fix-docker-memlock-settings.sh | Fix Docker memory lock limitations |
| fix-kernel-ionotify.sh | Increase kernel inotify watch limits |
| fix-kublet-cgroup-settings.sh | Fix kubelet cgroup configuration |
| fix-k8-manifest.sh | Repair Kubernetes manifest files |
| fix-netdata-cron.sh | Fix Netdata cron job configuration |
| fix-pam-limits | Configure PAM limits for system resources |
| fix-resolv-pull-settings.sh | Fix DNS resolution configuration |
| netdata-fix-systemd | Fix Netdata systemd service |
| netdata-configure-influxdb | Configure Netdata with InfluxDB backend |
| nfs-server-fix-systemd | Fix NFS server systemd configuration |
| calico_set_connectrack | Configure Calico connection tracking |

### 🛠️ Development Tools & Environment
| Script | Description |
|--------|-------------|
| configure_claude_mcp.sh | Configure Claude MCP servers for development |
| configure-dev-env.sh | Setup complete development environment |
| setup-neovim.sh | Setup Neovim with plugins and configuration |
| install-code-shell-tmux.sh | Install integrated code shell with tmux |
| install-compile-tools.sh | Install compilation and build tools |
| install-cgroup-tools.sh | Install cgroup management utilities |
| install-ctags.sh | Install ctags for code navigation |
| install-debug-symbols | Install debugging symbols for system libraries |
| ubuntu-generate-locale.sh | Generate locale configuration for Ubuntu |

### 🌐 Network & Storage Utilities
| Script | Description |
|--------|-------------|
| get-ip-netns | Get IP information from network namespaces |
| cloudflare_udpserver.py | Cloudflare UDP server implementation |
| apt-update.sh | Update remote hosts via SSH using apt |

### 🏗️ Build & Compilation Tools
| Script | Description |
|--------|-------------|
| buildkernel_ec2xenial.sh | Build custom kernel for EC2 Xenial instances |
| kernel-build-hardcore | Advanced kernel compilation utilities |
| kernel-functions.sh | Kernel development helper functions |
| compile-fluent-bit | Compile Fluent Bit from source |
| build-perf-repos | Build performance analysis repositories |
| clone_perf_lab_repos | Clone performance lab repositories |
| list-symbols-packages-v2.sh | List debug symbol packages |

### 🔍 Security & Auditing
| Script | Description |
|--------|-------------|
| backup_boss_monitor.sh | Backup Boss Monitor system configuration |
| create_report.sh | Generate comprehensive system reports |
| generate_goss_tests.sh | Generate Goss validation tests |

### 🧰 Utilities & Helpers
| Script | Description |
|--------|-------------|
| update-bossjones-debug-tools | Update debug tools from upstream repository |
| switch-to-nightly-build-bcc-tools | Switch to nightly BCC tools build |
| test-logger-syslog | Test syslog logging functionality |
| fake-logger | Fake logger for testing purposes |
| fake-fluentd | Mock Fluentd for development testing |
| get-all-broken-journald-logs | Retrieve corrupted journald log entries |
| color-echo-helper | Colored output helper for scripts |
| banner.sh | Display formatted banner messages |
| boss-update-grub.sh | Update GRUB bootloader configuration |
| boss-log | Boss system logging utility |
| echb | Enhanced echo with formatting |
| jmaps | Java memory analysis and mapping tools |

### ⚙️ Setup & Service Configuration
| Script | Description |
|--------|-------------|
| setup-journald-exporter.sh | Setup systemd journal log exporter |
| setup-prometheus-pve-exporter.sh | Setup Prometheus Proxmox VE exporter |
| install-config-sample | Sample configuration installer |
| install-config-sample-ubuntu | Ubuntu-specific configuration sample |

## Malcolm Jones
[Malcolm Jones](https://github.com/bossjones)

## Inspiration
[Takeshi Yonezu](https://github.com/tkyonezu)
