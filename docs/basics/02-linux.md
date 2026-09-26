# Baby Step 2: Linux for Security

## The concepts
- **Users and groups:** every process runs as a user. `root` (UID 0) can do almost anything, which is why containers should not run as root.
- **Permissions:** `rwx` for owner, group and others. `-rw-r-----` means the owner reads and writes, the group reads, others get nothing.
- **Processes:** running programs, each with a user, parent and arguments. Unexpected processes (a shell inside a web server
  container) are a classic intrusion sign.
- **Capabilities:** root's powers split into pieces (e.g. `NET_BIND_SERVICE`). Containers should drop all they don't need.
- **Logs:** the system's memory of what happened (`/var/log`, `journalctl`, and in Kubernetes, `kubectl logs`).

## Try it
```bash
id                          # your UID, GID and groups
ls -l /etc/passwd /etc/shadow 2>/dev/null   # (on Linux) world-readable vs root-only: why the difference?
ps -eo user,pid,ppid,comm | head -15        # who runs what
# Inside the lab's kind node (it's a Linux container):
docker exec secops-lab-worker ps -eo user,pid,comm | head
docker exec secops-lab-worker cat /proc/1/status | grep -i ^cap   # capability bitmasks of PID 1
```

**Go deeper:** [Linux security notes](../linux-security/README.md): firewalls, ACLs, SELinux/AppArmor, auditd, reverse proxies and built-in analysis tools.

## Check yourself
1. Why is a process running as root inside a container a risk?
2. What does `chmod 640 file` allow, and for whom?
3. Name two log sources you would check after a suspected break-in.
