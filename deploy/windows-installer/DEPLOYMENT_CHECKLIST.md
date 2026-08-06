# MyLikita — Deployment Checklist v0.1.0

> **One-page printable checklist.** Tick each box as you go.
> Full step-by-step guide: [`OFFLINE_INSTALLATION_GUIDE.md`](OFFLINE_INSTALLATION_GUIDE.md)

---

## ☐ Pre-install

| # | Task | Done |
|---|---|---|
| 1 | Download **`MyLikita-Setup-0.1.0.exe`** from the release page and copy to the server (USB/network share) | ☐ |
| 2 | Windows Server 2016+ or Windows 10/11 64-bit, **administrator rights** available | ☐ |
| 3 | **≥ 3 GB free disk space** on `C:\` | ☐ |
| 4 | **Static IP assigned** to the server (recommended — note it here: `____.____.____.____`) | ☐ |
| 5 | Ports **46990** (app) and **3306** (database) not in use by other software | ☐ |

---

## ☐ Install — 5 minutes of clicks, then wait

| # | Task | Done |
|---|---|---|
| 6 | **Double-click** `MyLikita-Setup-0.1.0.exe` → click **Yes** on security prompt | ☐ |
| 7 | Click **Next → Install** (no questions to answer) | ☐ |
| 8 | **Wait 5–15 minutes.** Progress bar may look stuck — it's working (database, services, firewall). **Do not close the window.** | ☐ |
| 9 | Write down the access URL from the final page (also saved in `C:\MyLikita\CREDENTIALS.txt`): | ☐ |
|   | • This server: `http://localhost:46990/` |   |
|   | • Network: `http://________:46990/` |   |

---

## ☐ First login — change the default password

| # | Task | Done |
|---|---|---|
| 10 | Open `http://localhost:46990/` in a browser on the server | ☐ |
| 11 | Log in with **username:** `admin` · **password:** `123456` | ☐ |
| 12 | **Change the password immediately.** If you see a facility setup wizard, set the admin password there. Otherwise: click your name in the top-right → **Profile** → **Change Password** → enter `123456`, pick a strong new password → **Save** | ☐ |
| 13 | Create separate staff accounts under **Admin → Manage Users** (don't share the admin account) | ☐ |

---

## ☐ Verify — other computers can connect

| # | Task | Done |
|---|---|---|
| 14 | From a staff computer on the same network, open `http://<SERVER-IP>:46990/` | ☐ |
| 15 | The MyLikita login page appears → login with the new admin password | ☐ |
| 16 | If it doesn't load: check the server IP (`ipconfig`), firewall rule "MyLikita", and antivirus. See troubleshooting in the full guide. | ☐ |

---

## ☐ SMS & Email setup — Termii + Resend (optional)

**The app works fully without SMS/email.** Fill this in only if you want patient reminders and notifications.

### Termii — SMS (and WhatsApp, optional)

| # | What you need | Where to get it | Your value | Done |
|---|---|---|---|---|
| T1 | Account | **termii.com** → create free account | Email: ______________ | ☐ |
| T2 | `TERMII_API_KEY` | Settings → Developers → API Keys | `_______________` | ☐ |
| T3 | `TERMII_SENDER_ID` | Settings → Sender ID → verify a name (e.g. `MyLikita`) | `_______________` | ☐ |
| T4 | `TERMII_CHANNEL` | Leave `generic` (use `dnd` only if you have a DND sender ID) | `generic` | ☐ |
| T5 | `TERMII_WHATSAPP_ID` *(optional)* | WhatsApp → Devices → device name | `_______________` | ☐ |

### Resend — email

| # | What you need | Where to get it | Your value | Done |
|---|---|---|---|---|
| R1 | Account | **resend.com** → create free account | Email: ______________ | ☐ |
| R2 | `RESEND_API_KEY` | API Keys → looks like `re_…` | `_______________` | ☐ |
| R3 | `EMAIL_FROM` | A **verified** sending address in Resend (or `onboarding@resend.dev` for testing) | `_______________` | ☐ |

### Apply the credentials after install

| # | Task | Done |
|---|---|---|
| 17 | Edit `C:\MyLikita\backend\.env` as Administrator (Notepad), fill in the values above, save | ☐ |
| 18 | Restart the app: open **Admin Command Prompt** → `"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita` | ☐ |
| 19 | Open **Admin → Setup → Reminder Health** → click **Send test SMS** / **Send test email** to verify | ☐ |
| 20 | In **Reminder Health → Notification channels** panel, tick SMS / WhatsApp / Email as needed, then **Save** | ☐ |

---

## ☐ That's it — you're live

**MyLikita is now running.** Staff use the network URL from step 9. The server needs no internet.

### Quick reference

| Action | Command (Admin Command Prompt) |
|---|---|
| **Restart the app** | `"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita` |
| **Check if running** | `"C:\MyLikita\runtime\nssm\nssm.exe" status MyLikita` |
| **Update to new version** | Double-click the new installer — data is preserved, never wiped |
| **Server IP changed** | Right-click `C:\MyLikita\scripts\update-ip.cmd` → Run as administrator |

### When things go wrong

| Problem | Action |
|---|---|
| Installer error | Send `C:\MyLikita\logs\install.log` to support |
| App errors / won't start | Send `C:\MyLikita\logs\err.log` to support |
| Can't connect from staff PC | Check IP, firewall rule "MyLikita" (`wf.msc`), antivirus |

---

## 📧 Support

**Email:** `support@mylikita.com`

Attach these logs so we can help you quickly:
- **Installation problems:** `C:\MyLikita\logs\install.log`
- **Application problems:** `C:\MyLikita\logs\err.log`
- **Your credentials file:** `C:\MyLikita\CREDENTIALS.txt` (tells us your access URLs)

---

*MyLikita v0.1.0 — one file, fully offline, no internet needed.*
