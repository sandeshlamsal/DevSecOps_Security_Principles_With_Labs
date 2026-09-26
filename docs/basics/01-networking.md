# Baby Step 1: How Computers Talk (Networking)

## The concepts
- **IP address:** the address of a machine (`93.184.215.14`, or `127.0.0.1` for "this machine").
- **Port:** a numbered door on that machine for a specific service (443 = HTTPS, 22 = SSH, 5432 = PostgreSQL).
  Every open port is part of the **attack surface**.
- **TCP vs UDP:** TCP makes a reliable connection first (the "three-way handshake": SYN, SYN-ACK, ACK). UDP just sends.
- **DNS:** turns names (`owasp.org`) into IP addresses. If DNS is tampered with, users go to the wrong server.
- **TLS:** encrypts the connection and proves the server's identity with a **certificate**. HTTPS = HTTP inside TLS.
- **Layers:** a simplified stack is *link → IP → TCP/UDP → TLS → HTTP*. Security controls exist at each layer (firewall at IP/port,
  TLS for transport, WAF and app logic for HTTP).

## Try it
```bash
dig +short owasp.org                         # DNS: name → IP
curl -sv https://owasp.org -o /dev/null 2>&1 | grep -E 'Connected|SSL connection|subject|issuer|HTTP/'
                                             # TCP connect, TLS version, certificate, HTTP status
lsof -iTCP -sTCP:LISTEN -n -P | head         # which ports is YOUR machine listening on, and which program owns each?
```
With the lab running (`make open`): `lsof -iTCP:3000 -sTCP:LISTEN -n -P` shows the port-forward is bound to `127.0.0.1` only,
so other machines on your network can't reach the vulnerable app. That's a deliberate control.

## Check yourself
1. What is the difference between an IP address and a port?
2. Why does it matter whether a service listens on `127.0.0.1` or `0.0.0.0`?
3. What two things does TLS give you? (Hint: privacy, and…?)
4. What could an attacker do if they could change DNS answers?
