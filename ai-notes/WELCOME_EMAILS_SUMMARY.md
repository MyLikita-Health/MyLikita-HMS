# Welcome Emails — Facility Admin + Staff

A non-blocking welcome email sent at the two moments a new person joins the product:

1. **Facility admin** — right after onboarding (cloud signup **and** offline claim). The email links to the **Facility Setup Guide** checklist, the same first-login interstitial the admin sees in-app.
2. **Staff** — right after an admin creates a user account (the Admin "Create User" form → `POST /auth/sign-up`). The email links to the login page.

The account/facility is **live regardless of email delivery** — email is fire-and-forget, after the DB work commits.

---

## 1. The `sendWelcome` contract

**File:** `backend/services/emailApi.js` (exported alongside the legacy `sendMail` / `newMail`; `require`d by `controller/onboarding.js` and `controller/users.js`).

```js
async function sendWelcome({ to, name, username, facilityName, appUrl, role } = {})
// → Promise<{ success: boolean }>   — ALWAYS resolves, never throws
```

| Field | Meaning |
|---|---|
| `to` | Recipient email. Missing/empty → immediate `{ success: false, error: 'No recipient email' }`. |
| `name` | Human name for the greeting. Empty → falls back to `'there'`. |
| `username` | Shown in the email (the recipient needs it to log in). |
| `facilityName` | Bolded in the email; also used in the subject line. |
| `appUrl` | Base URL (callers pass `req.protocol + '://' + req.get('host')`). Falls back to `https://app.mylikita.clinic` when absent. |
| `role` | **`'admin'` / `'Administrator'`** → the admin variant; **any other value** → the staff variant. |

### Variants

**Admin** (`role: 'admin'`):
- Subject: `Welcome to MyLikita — let's set up {facilityName}`
- Heading: "Welcome aboard"
- CTA button: **"Open the Setup Guide"** → `{appUrl}/me/admin/setup-guide`
- Copy: facility created, username shown, explains the live Setup Guide checklist and that it appears automatically on first login.

**Staff** (any other role):
- Subject: `You've been added to {facilityName}`
- Heading: "Welcome to the team"
- CTA button: **"Log in to MyLikita"** → `{appUrl}/auth`
- Copy: account created by an administrator, username shown, note to use the password the admin provided and change it from the profile.

Both variants render inside the shared `wrap(title, bodyHtml)` shell (same look as the legacy template sends) and use the `welcomeButton(url, label)` helper for the CTA pill.

### Security / hygiene

- **No plaintext passwords anywhere** — the email only carries the username.
- **All user-controlled fields are HTML-escaped** (`escapeHtml` on `name`, `username`, `facilityName`) so a username like `jane<script>` or a facility name with `&`/quotes can't inject markup. The subject line is plain text delivered as JSON (no header injection), so it uses the raw facility name.
- URL building: `guideUrl` / `loginUrl` are derived from `appUrl` (never user-supplied as a raw href).

---

## 2. Hooks

| Site | File / function | When | Notes |
|---|---|---|---|
| **Cloud onboarding** | `controller/onboarding.js` → `createFacility` (≈line 362) | After `t.commit()` succeeds | `role: 'admin'`, `appUrl` from the request; fires only when the admin supplied an email. |
| **Offline claim** | `controller/onboarding.js` → `claimFacility` (≈line 592) | After `t.commit()` succeeds | `role: 'admin'`, sent to `contactEmail`; `name: ''` (the claim wizard doesn't collect first/last name → generic greeting). Silently skipped when the local server has no transport configured. |
| **Staff creation** | `controller/users.js` → `create` (≈line 180) | Inside `User.create(...).then(...)`, after the row exists | Looks up the facility name first, then fires with `role: user.role`; only when the new user has an email. |

All three call sites are **fire-and-forget with `.catch(() => {})`** — belt-and-braces on top of `sendWelcome`'s internal catch.

---

## 3. Graceful-failure design

`sendWelcome` is deliberately written so **email can never break onboarding or user creation**:

1. **No-recipient guard** → resolves `{ success: false }` before touching the transport.
2. **Transport failures are caught** — including the **missing `RESEND_API_KEY` case**, where `config/nodemailer` rejects with `Email not sent: RESEND_API_KEY is not configured...`. The catch logs `[Email] Welcome to <to> skipped (admin|staff): <reason>` and returns `{ success: false, error }`.
3. **Always resolves** → callers never see an unhandled rejection, and the `.catch(() => {})` is purely defensive.
4. **Ordering** — the email is sent *after* the DB transaction commits (onboarding) or after the user row exists (staff), so the primary operation's success is never tied to email availability.

Net effect: a facility with no `RESEND_API_KEY` configured still onboards and creates users normally; email simply never goes out (and logs why).

---

## 4. RESEND setup

Transport lives in **`backend/config/nodemailer.js`** — the shared, Resend-backed `sendMail(options)` used by every email caller in the app (the old SMTP env vars are no longer read; `RESEND_API_KEY` is the single source of truth).

### To enable email

1. Create a key at **https://resend.com/api-keys**.
2. Add to `backend/.env`:
   ```
   RESEND_API_KEY=re_xxxxxxxx
   # optional — default is 'MyLikita <hello@mylikita.clinic>'
   EMAIL_FROM=MyLikita <hello@mylikita.clinic>
   ```
3. Restart the backend (`cd backend && node app.js`).

### Behaviour with no key

- `sendMail` **rejects** with `Email not sent: RESEND_API_KEY is not configured. Set it in the backend .env to enable email.` — callers surface it (reminder queue marks the email failed, the Reminder Health panel shows why, welcome emails log-and-skip). Nothing is silently "sent".
- Verify the key end-to-end from the Admin UI via the Reminder Settings **test-message** endpoint (Termii/Resend channels), which reports `configured: Boolean(process.env.RESEND_API_KEY)`.

### Transport details (for reference)

- POSTs to `https://api.resend.com/emails` with `Authorization: Bearer <key>`.
- Supports `from / to (string or array) / subject / text / html / attachments` (attachment content is **base64**).
- Returns `{ messageId, id }`; non-OK responses throw `Resend error: <message>`.

---

## 5. Verification notes (from implementation)

- Syntax + module load checks pass for `emailApi.js`, `onboarding.js`, `users.js`.
- Functional test captured the real payload for **both** variants: correct subjects, Setup Guide URL present in the admin email, username + facility present.
- Injection test: `name="<b>Jane</b>"`, `username="jane<script>"`, `facilityName="Test & Co Clinic"` → all correctly escaped, **no raw `<script>`** in the output.
- Graceful paths proven: no-recipient guard and unconfigured-RESEND both return `{ success: false }` without throwing.
- Code review findings applied: HTML-escaping of user-controlled fields; removed a dead `name` expression in the offline-claim hook.

---

## 6. Files touched

| File | Change |
|---|---|
| `backend/services/emailApi.js` | `sendWelcome`, `escapeHtml`, `welcomeButton` helpers; exported |
| `backend/controller/onboarding.js` | welcome hook in `createFacility` (cloud) + `claimFacility` (offline) |
| `backend/controller/users.js` | welcome hook in `exports.create` (staff) |
