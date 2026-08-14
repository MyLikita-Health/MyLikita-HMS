# MyLikita — Windows Troubleshooting: "Blank Page"

> **The symptom:** the browser shows a white page (or the MyLikita logo/title but
> nothing else) and the screen never becomes the login form.
>
> A blank page is **not** the server being offline — that shows "can't connect".
> A blank page means the server answered, but the app's **browser code crashed
> before drawing**. Work through the ladder below top to bottom. Most cases are
> step 4 (stale browser cache).

---

## Step 1 — Is the server healthy? (10 seconds)

Open on the **server itself** (or from a staff PC, replace `localhost` with the
server's IP):

```
http://localhost:46990/health
```

**Healthy** looks like (a short text page of JSON):

```json
{"status":"ok","app":"MyLikita","version":"0.1.2","db":"up","degraded":false,...}
```

| You see | Meaning | Go to |
|---|---|---|
| `status:"ok"`, `db:"up"` | Server + database fine — the fault is the browser | **Step 4** |
| `"db":"down"` | Database problem | **Step 3**, MySQL log |
| `degraded:true` | Update/migrations pending | Run the installer again, then **Step 4** |
| Page won't load / "can't reach" | Server not running | **Step 2** |

---

## Step 2 — Is the Windows service running? (1 minute)

Check the two MyLikita services (run in **Command Prompt as Administrator**):

```
sc query MyLikita
sc query MyLikitaMySQL
```

`STATE : 4 RUNNING` on both is normal. If the app service is stopped/error:

```
C:\MyLikita\runtime\nssm\nssm.exe restart MyLikita
```

then wait ~20 seconds and re-check **Step 1**. If MySQL is stopped:

```
C:\MyLikita\runtime\nssm\nssm.exe restart MyLikitaMySQL
```

> If restarting fixes it, the app was crashing on every boot — **Step 3** will
> tell you why.

---

## Step 3 — Read the logs (2 minutes)

Everything the app prints goes to **`C:\MyLikita\logs\`**:

| File | What it holds |
|---|---|
| `out.log` | Normal runtime output (requests, boot messages) |
| `err.log` | **Crashes and errors — start here** |
| `install.log` | The install-time log (only useful on a fresh install) |
| `mysql-error.log` | Database errors |

Look at the **last 50 lines** of `err.log`:

```
powershell -Command "Get-Content C:\MyLikita\logs\err.log -Tail 50"
```

What to look for: `Error`, `Cannot find module`, `SyntaxError`, `Uncaught`,
`EADDRINUSE` (another program took the port), or a long stack trace ending in
`at ...`. Anything that looks like a crash — copy the last ~30 lines into an
email to **MyLikita support** together with `install.log` (if the install is
recent) and the `version` value from Step 1.

---

## Step 4 — Clear the browser's stored site data (2 minutes)

The #1 cause on staff computers: the browser kept the **old broken copy** of the
app from before an update. (New installs also protect you — if the app fails to
draw at install time, the installer now reports the failure instead of
finishing.)

**Try the fast fix first** — a hard refresh:

- Press **Ctrl + Shift + R** (or hold **Shift** and click the refresh button).

Still blank? Clear the site's data properly. In **Google Chrome** or **Edge**:

1. Click the **padlock / "View site information"** icon left of the address bar.
2. Click **"Site settings"** (Chrome) or **"Cookies and site data"** (Edge).
3. Click **"Clear data"** (Chrome) or **"Manage cookies and site data" → trash
   icon** (Edge) for this site.
4. Reload the page (**F5**).

If the menu above is not visible, use the full clear:

1. **Ctrl + Shift + Delete**
2. Time range: **All time**
3. Tick **"Cached images and files"** and **"Cookies and other site data"**
4. Click **Clear data**, then reopen MyLikita.

> Since the latest update, MyLikita shows an **"Update available"** banner with
> a **Reload** button when the browser is serving stale code — clicking Reload
> is enough; you no longer need to force a refresh after updates.

---

## Step 5 — Still blank? Send this to support

Copy these four things into your support email:

1. `version` from `http://localhost:46990/health` (Step 1)
2. Last ~30 lines of `C:\MyLikita\logs\err.log`
3. `C:\MyLikita\logs\install.log` (only for installs younger than ~1 week)
4. Which browser + version (Chrome / Edge) and whether Step 4 fixed it

---

*MyLikita — Hospital Management System — https://mylikita.com — support: send the
items in Step 5 with "BLANK PAGE" in the subject.*
