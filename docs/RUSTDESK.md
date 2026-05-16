# RustDesk over Tailscale

You're skipping RustDesk's public relay servers. Instead, Tailscale gives
every machine a stable `100.x.x.x` IP and handles NAT traversal + encryption.
You enter that IP into RustDesk's "Control Remote Desktop" box and connect
directly, peer-to-peer. No port forwarding, no hbbs/hbbr servers, no keys.

## One-time setup on the Mac (the server side)

1. Open **Tailscale.app**, sign in, accept the macOS network extension prompt.
   Note the IP: `tailscale ip -4` (e.g. `100.101.102.103`).
2. Open **RustDesk**:
   - Settings → **Security**:
     - ☑ **Enable Direct IP Access**
     - **Password** → set a permanent password (not "one-time"). Strong one.
   - Settings → Display: choose a codec — H264 or H265 if your hardware
     supports it, otherwise VP9.
3. Grant macOS permissions when prompted:
   - System Settings → Privacy & Security → **Screen Recording** → enable RustDesk
   - **Accessibility** → enable RustDesk
   - **Input Monitoring** → enable RustDesk
4. (Optional) Settings → **General** → ☑ "Start on boot" so it survives reboots.

## From your phone / laptop (the client side)

1. Install Tailscale and sign into the same tailnet.
2. Install RustDesk.
3. Open RustDesk → in the **"Control Remote Desktop"** field, type the Mac's
   `100.x.x.x` Tailscale IP (or `mac-mini.tail-scale.ts.net` works on iOS/Android
   but **not** on RustDesk — it expects raw IPs).
4. Enter the permanent password from step 2 above.

That's it. The session is double-encrypted: WireGuard underneath, RustDesk on top.

## Troubleshooting

- **"Can't reach host"** — `tailscale ping <mac-ip>` from the client first.
  If that fails, the problem is Tailscale, not RustDesk.
- **Black screen on macOS** — Screen Recording permission isn't granted.
  Reopen System Settings → Privacy & Security → Screen Recording, toggle off+on.
- **Laggy** — switch codec to H265, lower the quality slider, or check
  `tailscale netcheck` to see if you're falling back to a DERP relay.
