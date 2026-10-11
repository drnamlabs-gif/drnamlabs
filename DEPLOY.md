# Deploying from a second machine

`./deploy.sh` publishes the built site by rsync over SSH to the host alias
`theta-server`. A fresh clone can build (`npm run build`) immediately, but it
cannot deploy until that machine has its **own** SSH key authorised on the
server.

## No private key lives in this repository — on purpose

`theta-server` is a **root** login on the Hetzner box that also serves
`theta.bunnyquant.com`, `bunnyquant.com`, `bunnyquant.vn` and
`corr.bunnyquant.com`. A private key for it must never be committed, not even
to a private repo:

- it would enter git history permanently — deleting the file later does not
  remove it, the history has to be rewritten;
- it would sit on GitHub's servers, and one accidental switch to public
  exposes root on five production sites at once;
- every clone becomes another copy of root access that can be lost with a
  laptop.

Each machine gets its own key instead. A key can then be revoked for one
machine without touching the others.

## Setting up a new machine

### 1. Windows only: use a bash shell

`deploy.sh` is a bash script and needs `rsync`, `ssh` and `curl`. Native
PowerShell will not run it. Either is fine:

- **WSL** (recommended) — `wsl --install`, then work inside the Linux home
  directory, not `/mnt/c`, or rsync permissions get strange.
- **Git Bash**, which ships with Git for Windows. It has `ssh` and `curl`;
  install `rsync` through its package manager if missing.

Run every command below inside that shell.

### 2. Generate a key on the new machine

The private half never leaves this machine.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_theta -N "" -C "<machine-name> deploy"
cat ~/.ssh/id_ed25519_theta.pub
```

Copy the printed line. It is a **public** key — safe to send over chat or
email.

### 3. Authorise it on the server

From a machine that already has access:

```bash
ssh theta-server 'echo "PASTE_THE_PUBLIC_KEY_LINE_HERE" >> ~/.ssh/authorized_keys'
```

### 4. Add the host alias on the new machine

Append to `~/.ssh/config` (create the file if absent, then `chmod 600` it):

```
Host theta-server
  HostName bunnyquant.com
  User root
  IdentityFile ~/.ssh/id_ed25519_theta
  IdentitiesOnly yes
```

### 5. Check, then deploy

```bash
ssh theta-server 'echo ok'      # expect: ok
npm install
npm run build
./deploy.sh --dry-run           # shows what would change, uploads nothing
./deploy.sh
```

## Keeping two machines in step

The repo is the only thing that syncs. Built output (`dist/`) and
`node_modules/` are ignored, so:

```bash
git pull --ff-only     # before starting work
git push origin main   # after committing
```

Deploy from whichever machine has the newest `main`. `deploy.sh` backs the
live site up to `/var/www/drnamlabs_backups/<timestamp>/` before writing, so a
deploy from a stale clone is recoverable — but pull first and avoid the
situation.

## Revoking a machine

Remove that machine's line from `~/.ssh/authorized_keys` on the server. Only
that machine loses access.
