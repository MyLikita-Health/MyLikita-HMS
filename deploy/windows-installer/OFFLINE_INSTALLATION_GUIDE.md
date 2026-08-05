# MyLikita — Offline Installation Guide (Windows)

Welcome! This guide walks you through installing **MyLikita Hospital System** on
your own Windows server — **with no internet connection required** during or
after installation.

You only need **one file**: the MyLikita installer (e.g. `MyLikita-Setup-1.0.0.exe`).

Everything else — the database program, the web server, and the application
itself — is already built into that single file. You double-click it, answer a
couple of standard prompts, and wait a few minutes. That's it.

---

## 1. What you need before you start

| Requirement | Details |
|---|---|
| **The installer file** | `MyLikita-Setup-<version>.exe` — copy it to the server, e.g. via USB stick or network share |
| **A Windows server** | Windows Server 2016 / 2019 / 2022, or Windows 10 / 11 (64-bit only) |
| **Administrator rights** | You must be able to click "Yes" on the User Account Control (UAC) prompt |
| **Free disk space** | About **2–3 GB** |
| **Internet** | **None needed** — the installer is fully self-contained |
| **A static IP (recommended)** | A fixed IP for the server makes it easier for staff computers to reach MyLikita (see step 6) |

> **Tip:** If your clinic has more than one server or a dedicated IT person,
> have them check that nothing else on the machine uses port **46990** (the
> app) or **3306** (the database). If those ports are busy, MyLikita
> automatically picks a free port — see the FAQ at the end.

---

## 1.1 SMS / email configuration sheet (optional — fill in before install)

MyLikita sends appointment reminders and notifications by **SMS** and **email**
through **Termii** (SMS/WhatsApp) and **Resend** (email). The app works fully
without these — but if you want patients to receive SMS/email reminders, the
server needs the credentials below.

**Fill this sheet in *before* you install**, so the values are ready when you
edit the server's configuration after setup (section 5.1). It is also the
handy thing to give whoever does the installation.

> 🔒 **Keep this sheet safe** — it contains API keys. Store it in a locked
> drawer or a password manager, and never email it as plain text. Anyone who
> has these keys can spend SMS/email credit on the accounts.

### Termii — SMS (and optional WhatsApp)

| # | What you need | Where to find it | Your value (fill in) |
|---|---|---|---|
| 1 | **Termii account** | Create a free account at **termii.com** | Account email: ________________ |
| 2 | **API Key** → `TERMII_API_KEY` | Termii → *Settings → Developers → API Keys* | _______________________________ |
| 3 | **Sender ID** → `TERMII_SENDER_ID` | *Settings → Sender ID* — verify an alphanumeric ID (e.g. `MyLikita`). This is the name patients see on their phone | ________________ (default `MyLikita`) |
| 4 | **Channel** → `TERMII_CHANNEL` | Leave `generic` unless you have a DND (marketing) sender ID | `generic` / `dnd` |
| 5 | **WhatsApp device name** → `TERMII_WHATSAPP_ID` *(optional)* | Termii → *WhatsApp → Devices* | ______________ (blank = WhatsApp off) |

**Checklist (tick when done):** ☐ Termii account created · ☐ Sender ID verified · ☐ API key copied

### Resend — email

| # | What you need | Where to find it | Your value (fill in) |
|---|---|---|---|
| 1 | **Resend account** | Create a free account at **resend.com** | Account email: ________________ |
| 2 | **API Key** → `RESEND_API_KEY` | Resend → *API Keys* (looks like `re_…`) | _______________________________ |
| 3 | **Sender address** → `EMAIL_FROM` | A domain/address you **verified** in Resend (or the test sender `onboarding@resend.dev` while trying things out) | `MyLikita <hello@your-clinic.com>` |

**Checklist (tick when done):** ☐ Resend account created · ☐ Sending domain verified · ☐ API key copied

> **After install:** type these values into `C:\MyLikita\backend\.env` (section
> 5.1 shows exactly where each one goes), restart the app, then open the
> **Reminder Health** screen — it now has **Send test SMS** / **Send test
> email** buttons that deliver a real test message, so you can confirm both
> keys work in seconds without waiting for an actual appointment reminder.
> Then use the **Notification channels** panel (section 5.2) to choose which
> channels this clinic actually uses.

---

## 2. Install MyLikita (step by step)

1. **Copy the installer to the server.**
   Put `MyLikita-Setup-<version>.exe` anywhere on the server, for example in
   `C:\MyLikita-Setup-1.0.0.exe` or on the Desktop.

2. **Double-click the installer.**
   Windows may show a blue **"Do you want to allow this app to make changes?"**
   prompt — click **Yes**.

3. **Click through the wizard.**
   A normal Windows install wizard opens. You will *not* be asked to configure
   anything — no database questions, no server details. Just accept the
   defaults and click **Next / Install**.

4. **Wait for the automatic setup (5–15 minutes).**
   After the files are copied, the installer runs the configuration
   automatically. The wizard will show a message like:
   > *"Configuring MyLikita (MySQL, database, Windows services)... This can take 5 to 15 minutes. Please do not close the installer."*
   The progress bar may appear stuck — **it is working**. Do not close the
   window and do not restart the server during this step.

   What it is doing (so you know what the time is spent on):
   - installing the built-in database (MySQL),
   - loading the initial data,
   - starting the app as a Windows service that auto-starts on boot,
   - opening the firewall port so other computers can connect.

5. **Note the information on the final page.**
   When finished, the last screen shows your **access URLs** and where your
   credentials are stored. Write these down or keep the file
   `C:\MyLikita\CREDENTIALS.txt`:
   ```
   Access from this machine : http://localhost:46990/
   Access from the network   : http://192.168.1.50:46990/
   ```
   Click **Finish**. A green console window may flash briefly — that is normal.

6. **That's it.** MyLikita is now running.

---

## 3. Logging in for the first time

Open your web browser (Chrome, Edge, or Firefox) on the server and go to:

```
http://localhost:46990/
```

or, from any staff computer on the same network:

```
http://<SERVER-IP>:46990/
```

Log in with the initial administrator account:

| Field | Value |
|---|---|
| **Username** | `admin` |
| **Password** | `123456` |

> **Security note:** change this password immediately after your first login
> (and create accounts for your staff instead of sharing it). The password is
> the default that ships with the system — anyone who reads this guide knows it.

### Change the default password (the system will not force you to)

MyLikita does **not** automatically ask you to change this password — the
account ships with the forced-change flag off, so the app will keep accepting
`123456` until you change it yourself. Do it once, right after your first
login:

1. Log in with `admin` / `123456`.
2. Click your **name / person icon** in the **top-right corner** of the page,
   then click **Profile** (this opens `http://localhost:46990/me/profile`).
3. Scroll to the **Change Password** section, just below *Personal
   Information*.
4. Enter your **current password** (`123456`), choose a **new password** (at
   least 8 characters — mix letters, numbers, and symbols), type it again to
   confirm, then click **Save / Change Password**.
5. From now on, log in with the new password. If you ever forget it, an
   administrator can reset it from **Admin → Manage Users**.

> **On a brand-new install**, you may instead be taken straight to a short
> facility setup wizard after logging in (it finalizes your facility name and
> details). That wizard also asks you to **choose the admin password** — if you
> set it there, this step is already done.

> **Tip:** instead of sharing the admin account with your staff, create a
> separate login for each staff member under **Admin → Manage Users**.

---

## 4. Letting other computers use MyLikita

1. The installer has **already opened the Windows firewall** for MyLikita — you
   usually don't need to do anything.
2. On each staff computer, open a browser and go to:
   ```
   http://<SERVER-IP>:46990/
   ```
   where `<SERVER-IP>` is the address shown on the installer's final page
   (e.g. `http://192.168.1.50:46990/`).
3. If a computer can't connect, check the **"Other PCs can't open the page"**
   row in the troubleshooting table below — the usual causes are a changed
   server IP or antivirus blocking the port.

> **How to find the server's IP:** on the server, open Command Prompt and type
> `ipconfig`. Look for the *IPv4 Address* on the active network adapter (e.g.
> `192.168.1.50`).

---

## 5. What was installed on your server

MyLikita installs everything into `C:\MyLikita\` and registers two Windows
services that start automatically when the server boots:

| Service | Purpose |
|---|---|
| **MyLikita** | The hospital system itself (web app on port 46990) |
| **MyLikitaMySQL** | The built-in database |

Useful files:

| File / folder | Purpose |
|---|---|
| `C:\MyLikita\CREDENTIALS.txt` | Your access URLs (created at install) |
| `C:\MyLikita\backend\.env` | Database password + security keys (auto-generated — don't edit unless you know what you're doing) |
| `C:\MyLikita\logs\install.log` | Installation log — send to support if something fails |
| `C:\MyLikita\logs\out.log`, `err.log` | Day-to-day app logs |

---

## 5.1 Optional: turn on SMS and email notifications (Termii + Resend)

MyLikita sends appointment reminders and notifications by **SMS** and **email**.
The system ships ready to use, but those two channels need an online account to
actually deliver messages. This is optional — the app works fully without them;
if you skip this step, the in-app notification bell still works, and the
Reminder Health screen (Admin → Setup → Reminder Health) will show SMS/email as
**"NOT configured"** so you know why nothing is being sent.

> If you filled in the **configuration sheet** in section 1.1, type the values
> from it into `.env` below — each line tells you which key it maps to.

**SMS — Termii** (termii.com):

1. Create a free account at termii.com and get an **API Key** from
   *Settings → Developers → API Keys*.
2. Verify a **Sender ID** (e.g. `MyLikita`) — this is the name patients see on
their phone.
3. On the server, edit `C:\MyLikita\backend\.env` with Notepad (run Notepad as
Administrator), fill in the key, and save:
   ```
   TERMII_API_KEY=YourTermiiApiKeyHere
   TERMII_SENDER_ID=MyLikita
   ```
4. *(Optional — WhatsApp)* In the same `.env` file, add the WhatsApp device
   name from *Termii Dashboard → WhatsApp → Devices* to enable WhatsApp
   reminders + booking confirmations alongside SMS/email:
   ```
   TERMII_WHATSAPP_ID=YourTermiiWhatsAppDeviceName
   ```

   > **How WhatsApp works here:** Termii delivers WhatsApp through the same
   > API as SMS — it just needs its own **device name** (the "sender" your
   > patients see in WhatsApp) plus the same API key. Your device name is
   > found under **Termii Dashboard → WhatsApp → Devices** (it looks like a
   > short word or your clinic's name, e.g. `myclinic-wa`). Both
   > `TERMII_API_KEY` and `TERMII_WHATSAPP_ID` must be present — if either is
   > missing, WhatsApp is simply not used (SMS/email keep working), and the
   > Reminder Health screen shows WhatsApp as **"NOT configured"**.

5. Restart the app: `"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita`
(Administrator Command Prompt).

**Email — Resend** (resend.com):

1. Create a free account at resend.com and get an **API Key** from
   *API Keys*.
2. Verify a sending **domain** (or use the test `onboarding@resend.dev` sender
while trying it out), so Resend knows you own the address emails come from.
3. In the same `C:\MyLikita\backend\.env` file, fill in the key and save:
   ```
   RESEND_API_KEY=re_YourResendApiKeyHere
   EMAIL_FROM=MyLikita <hello@your-clinic.com>
   ```
   (The `EMAIL_FROM` address must be one you verified in Resend.)
4. Restart the app as above.

You can confirm it worked on the **Reminder Health** screen — the SMS, Email
(and WhatsApp, if enabled) channels should now show **"configured"**.

### 5.2 Per-facility notification channels (SMS / WhatsApp / Email / In-app)

Once the channels are configured (section 5.1), you can decide **which
channels this clinic actually uses** — for example, mute SMS but keep email
and WhatsApp, or turn WhatsApp off while you test it.

1. Log in and open **Admin → Setup → Reminder Health** (the same screen as the
   test buttons above).
2. Find the **"Notification channels (per facility)"** panel.
3. Tick or untick each channel:

   | Channel | What it sends | Notes |
   |---|---|---|
   | **SMS (Termii)** | Text messages to patients' phones | Needs `TERMII_API_KEY` (section 5.1) |
   | **WhatsApp (Termii)** | WhatsApp messages to patients' phones | Needs `TERMII_API_KEY` **and** `TERMII_WHATSAPP_ID` (section 5.1 step 4) |
   | **Email (Resend)** | Emails to patients | Needs `RESEND_API_KEY` + `EMAIL_FROM` (section 5.1) |
   | **In-app bell** | Reminders shown inside MyLikita (no SMS/email cost) | Works fully offline; the notification bell in the top bar is separate and always on |

4. Click **Save channels**.

**How it behaves:**

- Turning a channel **off** stops new reminders and appointment notifications
  from being *scheduled* on it for this clinic. Existing queued messages are
  not cancelled.
- The setting is **per facility** — if you ever run several clinics on one
  server, each can have its own channel mix.
- Ticking a channel **on does not itself send anything** — the channel still
  needs its provider keys configured (the **"Channel providers"** pills at
  the top of the screen tell you at a glance which are configured vs.
  **NOT configured**).
- **Per-doctor toggles are on the same screen.** Below the facility-wide
  channels there is a **"Provider notification channels (per doctor)"**
  panel: it lists every clinician with a linked login and contact, with
  per-doctor **SMS / WhatsApp / Email** checkboxes. A channel must be on in
  BOTH the facility mix and the doctor's row for that clinician to receive
  appointment alerts (e.g. mute a doctor's SMS while the clinic keeps SMS
  for patients). Doctors appear there once linked to a user account (with
  phone/email) in **Appointments → Providers**.
- **Doctors can also change their own channels.** Each clinician sees a
  **"Notification Channels"** card on their own **My Profile** page
  (click their name/avatar, or the profile menu) with the same SMS /
  WhatsApp / Email toggles — no admin needed. Both views edit the same
  per-user setting, so whichever was saved last wins.

> **The in-app channel works even fully offline** (no SMS/email credit
> needed). It is the recommended default if a clinic has no Termii/Resend
> accounts yet — leave it ticked on.

---

## 6. Updating to a new version

Updates are just as easy as the first install:

1. Get the new installer file (`MyLikita-Setup-<new-version>.exe`) from MyLikita.
2. **Double-click it** and follow the same steps as the first install.
3. The installer **keeps all your data** — patient records, billing, settings.
   It will *not* wipe or re-import the database (it detects existing data and
   skips it).

There is no need to uninstall the old version first.

---

## 7. If your server's IP address changes

If the server later gets a new IP address (or you move it to a different
network), staff computers may not be able to reach MyLikita anymore. Fix it in
one step:

1. Right-click `C:\MyLikita\scripts\update-ip.cmd` → **Run as administrator**.
2. Press **Enter** to auto-detect the new IP (or type it in manually).
3. The script re-writes the address into the app and restarts the service.

---

## 8. Uninstalling

To remove MyLikita from the server:

1. Open **Control Panel → Programs and Features** (or **Settings → Apps**).
2. Find **MyLikita Hospital System** → **Uninstall**.

This removes the application but **keeps your database** by design — so if you
ever reinstall, all patient data is still there. To *completely* remove the
data too, run these two commands in an Administrator Command Prompt:

```cmd
net stop MyLikitaMySQL
sc delete MyLikitaMySQL
rmdir /s /q "C:\MyLikita\mysql-data"
```

> ⚠️ Only do the full removal if you are sure you don't need the data anymore.
> There is no undo.

---

## 9. Troubleshooting

| Symptom | What to check |
|---|---|
| **The installer shows an error** | Open `C:\MyLikita\logs\install.log` and send it to MyLikita support. You can also retry the setup without reinstalling by running `C:\MyLikita\scripts\reconfigure.cmd` as Administrator. |
| **The login page loads, but the app shows errors** | Check `C:\MyLikita\logs\err.log`. Usually a restart fixes it: `"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita` (see below). |
| **Other PCs can't open the page** | (1) Make sure they type `http://<SERVER-IP>:46990/` with the right IP. (2) Check the firewall rule **MyLikita** exists and is enabled: run `wf.msc` and look under *Inbound Rules*. (3) Check antivirus isn't blocking port 46990. (4) If the IP changed, run `update-ip.cmd` (step 7). |
| **The server was restarted — is MyLikita still running?** | Yes — both services start automatically. Just wait a minute after boot, then open the URL. |
| **Port 46990 is already in use** | The installer normally detects this. If the app still won't start, check `err.log` and contact support. |
| **I forgot where my login page is** | Read `C:\MyLikita\CREDENTIALS.txt`. |

**Handy commands** (Administrator Command Prompt). `nssm` is not on the PATH,
so use the full path:

```cmd
"C:\MyLikita\runtime\nssm\nssm.exe" start MyLikita     :: start the app
"C:\MyLikita\runtime\nssm\nssm.exe" stop MyLikita      :: stop the app
"C:\MyLikita\runtime\nssm\nssm.exe" restart MyLikita   :: restart the app
"C:\MyLikita\runtime\nssm\nssm.exe" status MyLikita    :: check if it's running (SERVICE_RUNNING = good)
net start MyLikitaMySQL   :: start the database
net stop MyLikitaMySQL    :: stop the database
```

---

## 10. Frequently asked questions

**Do I need the internet at any point?**
No. The installer contains everything and works on a completely offline server.

**Do I need a database licence or to install MySQL myself?**
No — a database is built into the installer and set up automatically.

**Which browser do staff need?**
Any modern browser — Chrome, Edge, or Firefox.

**How many computers can connect at the same time?**
There is no fixed limit. Performance depends on the server's hardware; a
standard office PC is fine for a small clinic.

**Can I install it on my normal office computer instead of a server?**
Yes — Windows 10/11 (64-bit) works, as long as the machine is always on and
reachable by staff.

**Will an update delete our data?**
No. Updates always preserve the database (see step 6).

**Something went wrong — where do I send the logs?**
Send these files to MyLikita support:
- `C:\MyLikita\logs\install.log` (installation problems)
- `C:\MyLikita\logs\err.log` (app problems)

---

*MyLikita Hospital System — offline deployment. Need help? Send the logs listed
above to MyLikita support.*
