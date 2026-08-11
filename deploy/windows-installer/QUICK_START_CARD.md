# MyLikita — Quick Start Card

> One-page summary of the offline install. Full details: [OFFLINE_INSTALLATION_GUIDE.md](OFFLINE_INSTALLATION_GUIDE.md).
> Print-friendly version: `QUICK_START_CARD.html` (open in a browser → Print → save as PDF).

---

## Install — 5 minutes of clicks

1. Copy **`MyLikita-Setup-<version>.exe`** to the server (USB or network share).
2. **Double-click** it → click **Yes** on the security prompt.
3. Click **Next / Install** — you are *not* asked to configure anything.
4. Wait while it sets itself up (**5–15 min**). Don't close the window — the
   progress bar may look stuck; it is working (database, data load, services,
   firewall).
5. Note the URLs on the final page (also saved in `C:\MyLikita\CREDENTIALS.txt`),
   then **Finish**.

## Log in

| | |
|---|---|
| **On the server** | `http://localhost:46990/` |
| **From staff computers** | `http://<SERVER-IP>:46990/` (find the IP with `ipconfig`) |

**Initial admin account** — change it at first login (public default):

| Username | Password |
|---|---|
| `admin` | `123456` |

> 🔒 The system will **not** force you to change this — do it yourself at first
> login: **top-right → Profile → Change Password** → enter `123456` + a new
> password → **Save**. (On a brand-new install you may instead be walked through
> a short facility setup wizard that lets you choose the admin password there.)
> Create separate accounts for staff, don't share this one.

## What you get

- Everything installed into **`C:\MyLikita\`** — app + built-in database, no extra software to install.
- Two services — **MyLikita** and **MyLikitaMySQL** — auto-start on boot.
- **Firewall already opened** so other computers can connect.
- Works with **no internet**, during or after install.

## Updates & quick fixes

- **Update:** run the new installer over the old one — **all data is kept**, never wiped.
- **Can't connect from another PC?** Check the IP, the firewall rule *MyLikita*, and antivirus on port 46990.
- **Server IP changed?** Right-click `C:\MyLikita\scripts\update-ip.cmd` → *Run as administrator*.
- **App stuck/erroring?** `"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita` (Admin prompt) — or in the app's Settings → Network tab, **Restart the MyLikita service**.
- **Is the server healthy?** Open `http://<server-ip>:46990/health` — `"status": "ok"` and `"db": "up"` means it's running. If the response also shows `"degraded": true`, the install is **behind on migrations** (stale) — run the migration step or re-run setup (shown on the installer's final page too).

## Need help?

Contact **support@mylikita.com** and attach:

- `C:\MyLikita\logs\install.log` — installation problems
- `C:\MyLikita\logs\err.log` — app problems

---

*MyLikita Hospital System — offline deployment · one file, no internet needed.*
