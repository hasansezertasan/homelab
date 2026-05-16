# Adding Dokploy later (via Lima)

Dokploy is a Docker-Swarm-based PaaS that officially supports Ubuntu/Debian
only. On Apple Silicon the cleanest path is a lightweight Linux VM via
[Lima](https://lima-vm.io). It's smaller than UTM, scriptable, and shares
your home directory by default.

## Install Lima

```
brew install lima
```

## Start an Ubuntu 22.04 VM

```
limactl start --name=dokploy template://ubuntu-lts \
  --cpus=4 --memory=8 --disk=60
```

(Adjust CPU/RAM to taste. Dokploy is light but your apps may not be.)

## Inside the VM — install Dokploy

```
limactl shell dokploy
sudo apt-get update && sudo apt-get -y upgrade
curl -sSL https://dokploy.com/install.sh | sudo sh
```

## Reach it from the Mac

Lima auto-forwards ports. Dokploy defaults to `:3000` — same as OpenChamber,
which is hard-coded in `launchd/dev.openchamber.openchamber.plist`. **Change
Dokploy's port** (e.g. forward to `:3001` via Lima's port-forwarding config)
rather than the OpenChamber plist — the rest of the repo's docs assume
OpenChamber on `:3000`.

To reach Dokploy from your phone over the tailnet:

```
# Install Tailscale inside the VM too:
limactl shell dokploy
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Now the VM has its own `100.x.x.x` IP and shows up in your tailnet alongside
the Mac. Bookmark `http://<vm-tailscale-ip>:3000`.

## Why not Docker Desktop on the Mac?

You could run Dokploy's Docker stack on Docker Desktop, but Dokploy uses
Docker **Swarm** features (services, configs, secrets) and assumes a real
Linux Docker host. The Swarm-on-Docker-Desktop path is fragile. A Lima VM
is closer to how Dokploy expects to run, and migrations to a real VPS or
Asahi later are trivial.
