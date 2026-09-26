# Linux Security Notes

A practical reference for securing and inspecting Linux hosts. Every container and Kubernetes node in this lab **is** Linux, so these
notes sit underneath almost every principle. Written to be shared: each section explains the concept, gives the commands, and says
what "good" looks like.

> Commands were checked on **Debian 13** (2026-09-26). RHEL/Fedora equivalents are noted where they differ. Beginners: start with
> [baby step 2](../basics/02-linux.md).

## Contents
1. [The host security model](#1-the-host-security-model)
2. [Users, groups, sudo and passwords](#2-users-groups-sudo-and-passwords)
3. [File permissions, special bits and ACLs](#3-file-permissions-special-bits-and-acls)
4. [Mandatory access control: SELinux, AppArmor, capabilities](#4-mandatory-access-control-selinux-apparmor-capabilities)
5. [Processes and services (systemd hardening)](#5-processes-and-services-systemd-hardening)
6. [Firewalls: netfilter, nftables, iptables, ufw, firewalld](#6-firewalls-netfilter-nftables-iptables-ufw-firewalld)
7. [Reverse proxies](#7-reverse-proxies)
8. [SSH hardening](#8-ssh-hardening)
9. [Logging and auditing (journald, auditd)](#9-logging-and-auditing-journald-auditd)
10. [Integrity and malware checks](#10-integrity-and-malware-checks)
11. [Kernel hardening (sysctl)](#11-kernel-hardening-sysctl)
12. [Patching](#12-patching)
13. [Disk and data protection](#13-disk-and-data-protection)
14. [Built-in and standard security analysis tools](#14-built-in-and-standard-security-analysis-tools)
15. [How containers use these same features](#15-how-containers-use-these-same-features)
16. [Hardening checklist](#16-hardening-checklist)
17. [Hands-on labs](#17-hands-on-labs)
18. [Interview questions](#18-interview-questions)

---

## 1. The host security model

```
   Network  → firewall (nftables), reverse proxy, TCP hardening (sysctl)
   Access   → SSH keys only, sudo least privilege, PAM, MFA
   Identity → users/groups, service accounts with no shell
   Files    → permissions, ACLs, no stray SUID, immutable configs, encrypted disks
   Policy   → SELinux / AppArmor (mandatory access control), capabilities, seccomp
   Services → minimal packages, systemd sandboxing, patched
   Evidence → journald, auditd, remote logging, integrity checks (AIDE)
```
The same [defence in depth](../principles/04-defense-in-depth.md) idea as everywhere else: an attacker who gets a shell as a web user should
still be stopped by permissions, MAC policy, a firewall on outbound traffic, and noticed by auditing.

---

## 2. Users, groups, sudo and passwords

| File | What's in it | Who can read it |
|---|---|---|
| `/etc/passwd` | Users, UIDs, home, **shell** | Everyone (no passwords here) |
| `/etc/shadow` | Password **hashes**, ageing | root only |
| `/etc/group`, `/etc/gshadow` | Groups and members | Everyone / root |
| `/etc/sudoers`, `/etc/sudoers.d/` | Who may run what as root | root (edit with `visudo`, which checks syntax) |
| `/etc/login.defs`, `/etc/security/pwquality.conf` | Password ageing and strength rules | — |
| `/etc/pam.d/` | Authentication stack (PAM): MFA, lockout, limits | — |

```bash
id; groups                                    # who am I, which groups
getent passwd | awk -F: '$3==0'               # every UID 0 account (should be only root)
awk -F: '($2==""){print $1}' /etc/shadow      # accounts with EMPTY passwords (root; should print nothing)
sudo -l                                       # what may I run with sudo?
sudo grep -rE 'NOPASSWD|ALL=\(ALL' /etc/sudoers /etc/sudoers.d/   # broad sudo rules to review
lastlog | head; last -n 20; lastb -n 20       # last logins / recent logins / FAILED logins (root)
chage -l alice                                # password ageing for a user
usermod -L alice; usermod -s /usr/sbin/nologin svc-app   # lock an account / service account with no shell
faillock --user alice                         # failed-login lockout counter (pam_faillock)
```

**Good looks like:** only `root` has UID 0; humans use their own accounts + `sudo` (no shared root password); sudo rules name specific
commands rather than `ALL`; service accounts have `/usr/sbin/nologin`; failed logins lock the account temporarily; MFA for SSH on bastions.

---

## 3. File permissions, special bits and ACLs

### Basic permissions
`-rwxr-x---` = owner `rwx`, group `r-x`, others `---`. For a directory, `x` means "may enter", `r` means "may list".

```bash
ls -l file; stat file            # permissions, owner, times
chmod 640 app.conf; chown root:app app.conf
umask                            # default mask for new files (027 is a good server default: no access for "others")
```

### Special bits

| Bit | On a file | On a directory | Risk / use |
|---|---|---|---|
| **SUID** (`4000`, `s` in owner x) | Runs as the **file's owner** (often root) | — | Every SUID-root binary is a privilege-escalation candidate; keep the list short and known |
| **SGID** (`2000`) | Runs as the file's group | New files inherit the directory's group | Shared team folders |
| **Sticky** (`1000`, `t`) | — | Only a file's owner can delete it | `/tmp` must have it (`drwxrwxrwt`) |

```bash
find / -xdev -perm -4000 -type f 2>/dev/null          # all SUID files: compare against a known-good list
find / -xdev -perm -2000 -type f 2>/dev/null          # all SGID files
find / -xdev -type f -perm -0002 2>/dev/null          # world-WRITABLE files (should be almost none)
find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null   # world-writable dirs WITHOUT the sticky bit (bad)
find / -xdev \( -nouser -o -nogroup \) 2>/dev/null    # files with no owner (left by deleted users)
```
On a stock Debian 13 container, the SUID list is short and expected: `chfn`, `su`, `newgrp`, `gpasswd`, `umount`, and a few more.

### ACLs (Access Control Lists)
Standard permissions allow one owner and one group. **ACLs** add permissions for extra, named users and groups without widening "others".

```bash
mkdir /srv/reports && chmod 750 /srv/reports      # owner rwx, group r-x, others nothing
setfacl -m u:bob:rx /srv/reports                  # let ONE extra user in, read-only
setfacl -d -m g:auditors:r /srv/reports           # DEFAULT ACL: new files inherit it
getfacl -p /srv/reports
setfacl -x u:bob /srv/reports                     # remove bob's entry
setfacl -b /srv/reports                           # remove all ACLs
```
Real output (Debian 13):
```
# file: /srv/reports
# owner: root
# group: root
user::rwx
user:bob:r-x
group::r-x
mask::r-x            ← the MASK caps what named users/groups can get; chmod on the group bits changes it
other::---
drwxr-x---+ 2 root root 4096 ... /srv/reports    ← the "+" means "has an ACL"
```
**Gotcha:** `ls -l` only shows the `+`. Always use `getfacl` when auditing access, or you'll miss who really has it.

### Immutable and append-only attributes
```bash
chattr +i /etc/resolv.conf     # immutable: not even root can modify or delete it until the flag is removed
chattr +a /var/log/app.log     # append-only: good for logs (attackers can't rewrite history)
lsattr /etc/resolv.conf
```
In a default Docker container this **fails**: `chattr: Operation not permitted`, because the container doesn't have
`CAP_LINUX_IMMUTABLE`. That's least privilege working ([section 15](#15-how-containers-use-these-same-features)).

---

## 4. Mandatory access control: SELinux, AppArmor, capabilities

Normal permissions are **discretionary** (DAC): the owner decides. **Mandatory access control** (MAC) adds a system-wide policy that even
root processes must obey. A compromised web server confined by MAC can't read `/etc/shadow`, even if file permissions would allow it.

| | **SELinux** (RHEL, Fedora, CentOS, Android) | **AppArmor** (Debian, Ubuntu, SUSE) |
|---|---|---|
| Model | Labels on every file and process; rules between labels | Per-program profiles based on file paths |
| Status | `getenforce`, `sestatus` | `aa-status` |
| Modes | Enforcing / Permissive / Disabled | enforce / complain |
| See denials | `ausearch -m AVC -ts recent`, `audit2why` | `journalctl -k \| grep apparmor` |
| Fix a label | `restorecon -Rv /path`, `semanage fcontext` | Edit the profile, `apparmor_parser -r` |
| Golden rule | **Never "fix" a denial with `setenforce 0`.** Find the right label or boolean (`getsebool -a`, `setsebool -P`) | Use complain mode to learn, then enforce |

### Capabilities
Root's power is split into ~40 **capabilities**. Give a program only the one it needs instead of full root.
```bash
getcap -r /usr/bin 2>/dev/null                 # binaries with file capabilities (another escalation path to review)
setcap cap_net_bind_service=+ep /usr/local/bin/web   # bind to port 80/443 without running as root
capsh --print                                  # capabilities of the current shell
grep Cap /proc/$$/status                       # raw capability bitmasks; decode with: capsh --decode=<hex>
```
Dangerous ones to watch: `CAP_SYS_ADMIN` (almost root), `CAP_SYS_PTRACE`, `CAP_SYS_MODULE`, `CAP_DAC_OVERRIDE`, `CAP_NET_ADMIN`.

---

## 5. Processes and services (systemd hardening)

```bash
ps auxf; pstree -p                           # what's running, as whom, started by what
ls -l /proc/<pid>/exe; cat /proc/<pid>/cmdline | tr '\0' ' '   # the real binary + arguments (malware often renames itself)
systemctl list-units --type=service --state=running
systemctl list-unit-files --state=enabled    # what starts at boot: disable what you don't need
systemd-analyze security                     # built-in exposure score (0 = best, 10 = worst) for every service
systemd-analyze security nginx.service       # per-setting breakdown for one service
```

systemd can sandbox any service with a few lines in a drop-in (`systemctl edit myapp`):
```ini
[Service]
User=myapp
NoNewPrivileges=yes           # no setuid escalation
ProtectSystem=strict          # / read-only except explicit paths
ReadWritePaths=/var/lib/myapp
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service  # seccomp allow-list
```
Re-run `systemd-analyze security myapp` and watch the score drop. It's the same idea as a Kubernetes `securityContext`.

---

## 6. Firewalls: netfilter, nftables, iptables, ufw, firewalld

**netfilter** is the packet-filtering engine inside the Linux kernel. The others are front-ends to it:

| Tool | What it is | Typical distro | Use it when |
|---|---|---|---|
| **nftables** (`nft`) | The modern netfilter interface: one tool for IPv4, IPv6, ARP, bridges | Default backend on Debian 10+, RHEL 8+ | Writing rules directly (recommended) |
| **iptables** | The legacy interface (on modern systems often `iptables-nft`, translating to nftables) | Older systems, Docker, Kubernetes kube-proxy | Reading existing rules; legacy scripts |
| **ufw** | "Uncomplicated Firewall": simple front-end | Ubuntu | Simple hosts |
| **firewalld** | Zone-based front-end with a D-Bus API | RHEL, Fedora | RHEL family |

### Concepts
- **Tables → chains → rules.** Base chains hook into the packet path: `input` (to this host), `output` (from this host), `forward` (routed through it).
- **Default policy `drop`**, then allow what's needed. That's [secure defaults](../principles/06-secure-defaults.md) for the network.
- **Stateful:** allow `established,related` so replies to your own connections get back in.
- **Filter outbound too.** Egress filtering stops a compromised server from downloading tools or sending data out.

### nftables: a default-deny host (checked on Debian 13)
```bash
nft add table inet filter
nft add chain inet filter input '{ type filter hook input priority 0; policy drop; }'
nft add rule  inet filter input ct state established,related accept
nft add rule  inet filter input iif lo accept
nft add rule  inet filter input tcp dport 22 ct state new limit rate 10/minute accept   # SSH, rate-limited
nft add rule  inet filter input tcp dport { 80, 443 } accept
nft list ruleset
```
Real output:
```
table inet filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iif "lo" accept
		tcp dport 22 ct state new limit rate 10/minute burst 5 packets accept
	}
}
```
Persist it in `/etc/nftables.conf` and `systemctl enable --now nftables`. **Test from a second session before closing the first**, so a
mistake can't lock you out.

### The same policy with the other front-ends
```bash
# iptables (legacy)
iptables -P INPUT DROP
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -L -n -v --line-numbers          # list with counters

# ufw (Ubuntu)
ufw default deny incoming; ufw default allow outgoing
ufw limit 22/tcp                          # allow SSH with built-in brute-force rate limiting
ufw allow 443/tcp; ufw enable; ufw status verbose

# firewalld (RHEL)
firewall-cmd --get-active-zones
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --remove-service=cockpit
firewall-cmd --reload; firewall-cmd --list-all
```

### Related protection
- **fail2ban:** watches logs and temporarily bans IPs with repeated failed logins (`fail2ban-client status sshd`).
- **Kubernetes note:** kube-proxy and CNIs write their own netfilter rules. Don't hand-edit them on nodes; use **NetworkPolicy**
  ([Principle 04](../principles/04-defense-in-depth.md)).

---

## 7. Reverse proxies

A **reverse proxy** sits in front of your application servers and receives all client traffic for them (nginx, HAProxy, Envoy, Traefik,
Caddy, Apache). A **forward proxy** does the opposite: it sits in front of *clients* and controls their outbound traffic (e.g. Squid,
corporate web proxies).

```
Client ──HTTPS──► [ Reverse proxy ] ──HTTP/mTLS──► App servers (private)
                   TLS termination, headers, rate limits, path allow-list, WAF, logs
```

**Why it's a security control:**

| Function | Protects against |
|---|---|
| Single, hardened entry point; app servers stay private | Direct attacks on app servers; [attack surface](../principles/05-attack-surface-reduction.md) |
| TLS termination with modern settings | Downgrade and weak-cipher attacks |
| Security headers (HSTS, CSP, X-Content-Type-Options) | XSS, clickjacking ([Principle 06](../principles/06-secure-defaults.md)) |
| Path allow/deny rules | Exposed admin, debug and file areas: this is plan step **B1** for Juice Shop (F-005, F-006, F-013–F-015) |
| Rate limiting and connection limits | Brute force, credential stuffing, some DoS |
| Request size and time limits | Resource exhaustion, slowloris |
| WAF module (ModSecurity/Coraza with the OWASP Core Rule Set) | Common injection patterns: a **virtual patch**, not a fix |
| Hide version banners | Makes targeted exploits slightly harder |
| Central access logs | Detection and forensics |

### A hardened nginx example (fronting Juice Shop)
```nginx
server_tokens off;                                          # no version in headers/error pages
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

server {
  listen 443 ssl;
  http2 on;
  server_name shop.example.test;
  ssl_certificate     /etc/nginx/tls/shop.crt;
  ssl_certificate_key /etc/nginx/tls/shop.key;
  ssl_protocols TLSv1.2 TLSv1.3;                            # no SSLv3/TLS1.0/1.1

  client_max_body_size 1m;                                  # request size limit
  client_body_timeout 10s; client_header_timeout 10s;       # slow-request protection

  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Content-Type-Options nosniff always;
  add_header Content-Security-Policy "default-src 'self'" always;
  add_header Referrer-Policy strict-origin-when-cross-origin always;

  # Virtual patch for audit findings F-005, F-006, F-013, F-014, F-015
  location ~ ^/(ftp|infrastructure|encryptionkeys|support/logs|metrics)(/|$) { return 404; }

  location = /rest/user/login {                             # brute-force protection on login
    limit_req zone=login burst=5 nodelay;
    proxy_pass http://juice-shop:3000;
  }
  location / {
    proxy_pass http://juice-shop:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
server { listen 80; return 301 https://$host$request_uri; }   # HTTP → HTTPS
```
Check it: `nginx -t` (syntax), `curl -sI https://…` (headers), `testssl.sh` or `nmap --script ssl-enum-ciphers -p 443` (TLS config).

**Trust boundary gotcha:** the app must only trust `X-Forwarded-For` from the proxy. If clients can reach the app directly, they can forge
that header and fake their IP.

---

## 8. SSH hardening

`/etc/ssh/sshd_config` (or a drop-in in `/etc/ssh/sshd_config.d/`):
```
PermitRootLogin no
PasswordAuthentication no           # keys only
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey     # or "publickey,keyboard-interactive" for key + MFA
AllowGroups ssh-users               # allow-list who may log in at all
MaxAuthTries 3
LoginGraceTime 20
X11Forwarding no
AllowTcpForwarding no               # unless needed (bastions)
ClientAliveInterval 300
ClientAliveCountMax 2
```
```bash
sshd -t                     # syntax check BEFORE restarting (don't lock yourself out)
sshd -T | grep -iE 'permitrootlogin|passwordauthentication|allowgroups'   # the EFFECTIVE config, all includes merged
ssh-keygen -t ed25519 -C "you@laptop"     # modern key type
ssh-keygen -lf ~/.ssh/id_ed25519.pub      # fingerprint, to verify keys out of band
```
Better still: no inbound SSH at all. Use a bastion with MFA, SSH certificates (short-lived, signed by a CA), or cloud session managers
(Azure Bastion, AWS SSM). Tool: **ssh-audit** checks a server's algorithms and config.

---

## 9. Logging and auditing (journald, auditd)

| Log | Where | What to look for |
|---|---|---|
| Authentication | `/var/log/auth.log` (Debian) · `/var/log/secure` (RHEL) · `journalctl -u ssh` | Failed logins, new sudo use, new users |
| System journal | `journalctl` | Service crashes, kernel messages, AppArmor/SELinux denials |
| Kernel | `journalctl -k`, `dmesg` | Module loads, segfaults, denials |
| Audit | `/var/log/audit/audit.log` | Everything auditd rules capture |
| Package changes | `/var/log/dpkg.log`, `/var/log/apt/history.log` · `dnf history` | Unexpected installs |

```bash
journalctl -u ssh --since "1 hour ago" | grep -i "failed"
journalctl -p warning -b                     # warnings and worse since boot
who; w; last -n 20; lastb -n 20              # who's on / recent logins / failed logins
```

### auditd: the kernel audit framework
Records security-relevant events (file access, syscalls, commands) with the user who did them, even after `sudo`.
```bash
auditctl -w /etc/passwd -p wa -k identity          # watch writes and attribute changes to /etc/passwd
auditctl -w /etc/sudoers -p wa -k sudoers
auditctl -a always,exit -F arch=b64 -S execve -F euid=0 -k root-commands   # every command run as root
auditctl -l                                         # current rules (persist them in /etc/audit/rules.d/*.rules)
ausearch -k identity -i                             # search by key, human-readable
aureport --auth --failed                            # summary report of failed authentications
aureport -x --summary                               # most-executed programs
```
**Ship logs off the host** (rsyslog/journald forwarding, a Fluent Bit agent, or a SIEM agent). An attacker with root can edit local logs;
they can't edit what already left the machine.

---

## 10. Integrity and malware checks

| Tool | What it checks | Built in? |
|---|---|---|
| `debsums -c` (Debian) · `rpm -Va` (RHEL) | Installed package files vs the package's checksums: changed binaries stand out | `rpm -V` built in; `debsums` is a package |
| **AIDE** | Takes a baseline of file hashes and permissions, then reports changes (`aide --init`, `aide --check`) | Package |
| **rkhunter / chkrootkit** | Known rootkit signatures, suspicious files and settings | Packages |
| **ClamAV** | Antivirus signatures (`freshclam`, `clamscan -r /srv`) | Package |
| `apt-key` / `rpm --checksig` / signed repos | Package signatures, so you only install what the distro signed | Built in |

Run integrity checks from a **known-good** source (a read-only baseline stored off the host), because a rootkit can lie to tools on the machine it controls.

---

## 11. Kernel hardening (sysctl)

```bash
sysctl -a 2>/dev/null | grep -E 'randomize_va_space|tcp_syncookies|rp_filter|ip_forward'   # inspect
```
Recommended settings in `/etc/sysctl.d/99-hardening.conf`, applied with `sysctl --system`:

| Setting | Value | Why |
|---|---|---|
| `kernel.randomize_va_space` | `2` | Full ASLR (the Debian 13 default, confirmed: `= 2`) |
| `kernel.kptr_restrict` | `2` | Hide kernel pointers from users (defeats some exploits) |
| `kernel.dmesg_restrict` | `1` | Only root reads the kernel log |
| `kernel.yama.ptrace_scope` | `1`–`2` | Stop processes from attaching to other processes (credential theft from memory) |
| `kernel.unprivileged_bpf_disabled` | `1` | Reduce kernel attack surface |
| `fs.protected_symlinks`, `fs.protected_hardlinks` | `1` | Block /tmp symlink attacks |
| `fs.suid_dumpable` | `0` | No core dumps from SUID programs (they may contain secrets) |
| `net.ipv4.tcp_syncookies` | `1` | SYN-flood protection (default `= 1`, confirmed) |
| `net.ipv4.conf.all.rp_filter` | `1` | Drop spoofed source addresses |
| `net.ipv4.conf.all.accept_redirects`, `send_redirects`, `accept_source_route` | `0` | Stop routing tricks |
| `net.ipv4.ip_forward` | `0` | Unless the host is a router. **Kubernetes nodes need `1`** |

---

## 12. Patching

```bash
apt list --upgradable; apt-get upgrade            # Debian/Ubuntu
dnf check-update; dnf upgrade --security          # RHEL/Fedora: security fixes only
needrestart                                       # which services still run OLD libraries after an update (Debian)
dnf needs-restarting -r                           # RHEL: is a reboot required?
```
Automate it: `unattended-upgrades` (Debian/Ubuntu) or `dnf-automatic` (RHEL) for security updates, plus a regular reboot window
(or kernel live patching). **Patching without restarting doesn't fix running processes.** That's why `needrestart` matters.

---

## 13. Disk and data protection

- **Full-disk encryption:** LUKS (`cryptsetup luksFormat`, `cryptsetup status`) protects data if a disk or laptop is stolen. In the cloud, provider encryption at rest + customer-managed keys (lab AZ-5).
- **Mount options** in `/etc/fstab`: `nodev,nosuid,noexec` on `/tmp`, `/var/tmp`, `/dev/shm` and removable media, so attackers can't run what they drop there.
- **Secrets on disk:** `chmod 600`, owned by the service user; better, fetched at runtime from a secrets manager ([Principle 09](../principles/09-protect-data-and-secrets.md)).
- **Backups:** encrypted, off-host, and **restore-tested**.

---

## 14. Built-in and standard security analysis tools

**Built in** = present on a typical minimal install (core utilities, procps, iproute2, util-linux, systemd). Others are one package away.

| Question | Tool | Built in? | Example |
|---|---|---|---|
| Who am I, what can I do? | `id`, `groups`, `sudo -l` | ✅ | `sudo -l` |
| Who's logged in / who logged in? | `who`, `w`, `last`, `lastb`, `lastlog` | ✅ | `last -n 20` |
| What's listening? | `ss` (replaces `netstat`) | ✅ | `ss -tulpn` |
| Which process has which file/socket open? | `lsof` | package | `lsof -i -P -n` |
| What's running? | `ps`, `pstree`, `top`, `/proc` | ✅ | `ps auxf` |
| What starts at boot? | `systemctl` | ✅ | `systemctl list-unit-files --state=enabled` |
| How exposed is each service? | `systemd-analyze security` | ✅ | score per service |
| File permissions and ownership | `ls -l`, `stat`, `find -perm` | ✅ | SUID hunt in §3 |
| ACLs / attributes | `getfacl` / `lsattr` | `acl` pkg / `e2fsprogs` | `getfacl -p /srv` |
| Capabilities | `getcap`, `capsh` | `libcap2-bin` | `getcap -r /usr` |
| MAC status | `getenforce`, `sestatus` / `aa-status` | ✅ on RHEL / Ubuntu | `aa-status` |
| Firewall rules | `nft list ruleset`, `iptables -L -n -v` | ✅ (usually) | §6 |
| Logs | `journalctl` | ✅ | `journalctl -p warning -b` |
| Audit trail | `auditctl`, `ausearch`, `aureport` | `auditd` pkg | `aureport --auth --failed` |
| Package integrity | `rpm -Va` / `debsums` | ✅ RHEL / pkg | `rpm -Va` |
| TLS check | `openssl s_client` | ✅ | `openssl s_client -connect host:443 -servername host` |
| Traffic capture | `tcpdump` | package | `tcpdump -i any port 443 -c 20` |
| Trace a process | `strace` | package | `strace -f -e trace=network -p <pid>` |
| **Full host audit** | **Lynis** | package | `lynis audit system` (below) |
| **Compliance scan** (CIS, STIG) | **OpenSCAP** (`oscap`) | package | `oscap xccdf eval --profile cis ...` |
| Network scan (**your own** hosts only) | `nmap` | package | `nmap -sV localhost` |
| File integrity | AIDE | package | §10 |
| Rootkits / malware | rkhunter, chkrootkit, ClamAV | packages | §10 |
| Brute-force defence | fail2ban | package | §6 |
| SSH config audit | ssh-audit | package / pip | §8 |

### Lynis: a real run
Lynis is an open-source host auditor: it runs hundreds of checks and prints warnings, suggestions and a hardening index.
```bash
apt-get install -y lynis        # or dnf install lynis
lynis audit system --quick
```
On a stock `debian:13-slim` container (2026-09-26):
```
  Warnings (1):
  Suggestions (40):
  Hardening index : 55 [###########         ]
  Tests performed : 236
```
A container isn't a full host (no bootloader, kernel or SSH), so some tests don't apply. Run it on a real VM or a kind node for a fuller
picture, then work through the suggestions and re-run to watch the index rise.

---

## 15. How containers use these same features

A container is just a Linux process with extra kernel isolation, so everything above applies, packaged differently:

| Linux feature | What it does for containers | Kubernetes setting |
|---|---|---|
| **Namespaces** (pid, net, mnt, user, ipc, uts) | Separate views of processes, network and filesystem | Default; `hostPID`/`hostNetwork: true` break it (forbidden by PSS restricted) |
| **cgroups** | CPU and memory limits | `resources.limits` |
| **Capabilities** | Root's powers, trimmed | `capabilities: {drop: [ALL]}`; that's why `chattr +i` failed in our container (§3) |
| **seccomp** | Syscall allow-list | `seccompProfile: {type: RuntimeDefault}` |
| **AppArmor / SELinux** | MAC confinement | `appArmorProfile` / `seLinuxOptions` |
| **Users** | Non-root inside the container | `runAsNonRoot: true`, `runAsUser` |
| **Read-only filesystem** | Nothing to modify | `readOnlyRootFilesystem: true` |
| **netfilter** | Pod networking and policies | NetworkPolicy (the CNI writes the rules) |

This is why the [hardened manifest](../../findings/REMEDIATION.md#a1-hardened-manifest-f-001-f-002-f-009-f-021) matters: each line turns
on a Linux protection.

---

## 16. Hardening checklist

Aligned with the ideas in the CIS Benchmarks (use the benchmark for your exact distro in real work):

- [ ] Minimal install; unused packages and services removed (`systemctl list-unit-files --state=enabled`)
- [ ] Automatic security updates + a reboot/restart plan (`needrestart`)
- [ ] Only root has UID 0; no empty passwords; service accounts use `nologin`
- [ ] `sudo` rules are specific; no shared root password
- [ ] SSH: keys only, no root login, `AllowGroups`, MFA or a bastion
- [ ] Firewall default-deny inbound (and ideally outbound), SSH rate-limited
- [ ] SELinux enforcing / AppArmor profiles enforced
- [ ] SUID/SGID list reviewed; no world-writable files; `/tmp` sticky + `noexec`
- [ ] Hardened sysctl (§11)
- [ ] auditd rules for identity, sudoers and root commands; logs shipped off the host
- [ ] File integrity baseline (AIDE) stored off the host
- [ ] Disks encrypted; secrets `600` or, better, not on disk
- [ ] Lynis / OpenSCAP scan on a schedule, with the score tracked over time

---

## 17. Hands-on labs

All of these run in a throwaway container or a kind node, so nothing on your Mac changes.

```bash
docker run --rm -it --cap-add NET_ADMIN debian:13-slim bash      # a disposable Linux box
apt-get update && apt-get install -y acl nftables iproute2 libcap2-bin procps lynis
```

| Lab | Task | Done when |
|---|---|---|
| L1 | **SUID audit:** list SUID/SGID files; explain why each needs it | A table with a reason per binary |
| L2 | **ACLs:** give one extra user read-only access to a directory without changing "others"; add a default ACL; check with `getfacl` | `getfacl` shows the entries and `+` in `ls -l` |
| L3 | **nftables:** build the default-deny rule set in §6; prove port 22 is rate-limited by reading the counters (`nft list ruleset -a`) | Rule set persisted to a file |
| L4 | **Lynis:** audit the container, fix 5 suggestions, re-run | Hardening index goes up; before/after recorded |
| L5 | **Capabilities:** run a container with `--cap-drop ALL`, try `chown` and `ping`; add back only what's needed | You can explain each failure |
| L6 | **Reverse proxy (plan step B1):** put nginx in front of Juice Shop with the §7 config; prove `/ftp` etc. return `404` and headers appear | Evidence added to F-005, F-006, F-013–F-015 |
| L7 | **auditd** (in a VM, since containers can't load audit rules): watch `/etc/passwd`, add a user, find the event with `ausearch -k identity -i` | Event shows the real user behind `sudo` |
| L8 | **kind node inspection:** `docker exec -it secops-lab-worker bash`, then `nft list ruleset \| head -50` to see the rules kube-proxy wrote | You can point to the rules for the `juice-shop` Service |

---

## 18. Interview questions
1. Walk me through hardening a fresh Linux server that will be exposed to the internet.
2. What's the difference between DAC and MAC? Give an example where MAC stops an attack that DAC doesn't.
3. Why is a SUID-root binary risky? How would you find them all?
4. When would you use ACLs instead of groups? What's the ACL mask?
5. nftables vs iptables vs ufw vs firewalld: how do they relate?
6. What does a reverse proxy add to security? What are its limits?
7. How do you confirm what SSH configuration is actually in effect?
8. An attacker had root on a box. Why can't you trust its local logs or tools, and what do you do instead?
9. What Linux kernel features make containers work, and which Kubernetes settings map to them?
10. What does `systemd-analyze security` tell you, and how would you improve a service's score?
