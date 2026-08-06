# How MyLikita Pricing Works — Plain-Terms Guide

*Last updated: August 6, 2026 · Source of truth: the `subscription_plans` table (editable by a MyLikita super admin at any time).*

---

## 1. The big picture

MyLikita is a **paid platform** — it is not free. Every facility gets a **14-day free trial** when they onboard, and after that they pay for one of **three tiers** (Basic, Standard, Premium) in one of two ways:

| Deployment | How you pay |
|---|---|
| **Cloud (online)** | Monthly subscription, or per-use ("pay-as-you-go") for hospitals |
| **Offline (own server / downloaded installer)** | Yearly license that can cover 1, 2, 5 or more years |

There are **two product lines** with their own price lists:

- **General Hospital / Clinic software**
- **Dental practice software**

A facility can change plan or renew at any time from **Settings → My Plan** (the "Upgrade or change plan" button). Payment is collected through **Paystack** (card / bank transfer / USSD).

---

## 2. General Hospital pricing

### Monthly subscription (cloud)

| Tier | Price (NGN) | What you get |
|---|---|---|
| **Basic** | ₦50,000 / month | Record Module (patient registration), Doctor Module (documentation & consultation), Nursing Module |
| **Standard** | ₦100,000 / month | Everything in Basic, plus Laboratory, Pharmacy, and the Account module (patient billing, revenue & expense reports, health insurance) |
| **Premium** | ₦150,000 / month | Everything in Basic & Standard, plus full accounting, inventory management, radiology, theatre module, HMO interface, and appointment scheduling |

### Facility-size bands (monthly subscription)

The monthly price is tiered by how many visits the facility does per month:

| Tier | Monthly visits | Subscription (NGN) |
|---|---|---|
| Basic | 0 – 100 | 50,000 |
| Standard | 101 – 250 | 100,000 |
| Premium | 251+ | 150,000 |

### Pay-as-you-go (online, per use)

A hospital on the pay-as-you-go model is charged per event instead of (or in addition to) a fixed subscription. Current per-event rates:

| Event | Cost (NGN) |
|---|---|
| New patient visit | 1,000 |
| Follow-up visit | 500 |
| Pharmacy request | 300 |
| Laboratory processed | 300 |
| **Surgery / theatre processed** | **300** |

> The surgery/theatre charge was added so that theatre usage is tracked and billed just like the other services.

---

## 3. Dental practice pricing

Dental plans are sold **per month** or **per year** (a yearly purchase is effectively a 1-year license).

| Tier | Per month | Per year | What you get |
|---|---|---|---|
| **Basic** | ₦25,000 | ₦250,000 | Record Module (patient registration), Dental Module (documentation & consultation), Account Module (basic billing). Up to 3 doctors, up to 5,000 patients, smart scheduling, dental chart, billing & quotes, email support |
| **Standard** | ₦50,000 | ₦500,000 | Everything in Basic, plus Dental Lab Module, full Account Module, Pharmacy Module (Dental Care Shop). Up to 7 practitioners, unlimited patients, advanced medical records, manual WhatsApp reminders, advanced reports, priority support, inventory management |
| **Premium** | ₦100,000 | ₦1,000,000 | Everything in Standard, plus full accounting, health insurance / HMO interface, unlimited practitioners, online booking & records, multi-specialty charts & clinical records, multi-specialties (Dentistry, Medicine, Wellness…), automatic WhatsApp reminders |

---

## 4. Offline (own server) — yearly licenses

Facilities that install the software offline (the downloaded installer) don't pay monthly. Instead:

- They buy a **yearly license** for their tier — e.g. Basic Dental ₦250,000/year.
- A license can be bought for **1, 2, 5 or more years** at once (multi-year purchases stack — buying 2 years adds 2 years to the expiry date).
- The license is **signed by MyLikita** and activated on the offline server (no internet needed to verify it — the server checks the signature with an embedded public key).
- **Renewal happens from inside the app**: when the offline server has internet, Settings → Offline License → "Check for renewal" phones home to MyLikita and pulls the authoritative status. Customers can also call us if they have problems.
- The offline license is preserved across reinstallations so a reinstall never kills an active license.

---

## 5. What happens with the free trial and after expiry

- **Trial:** every new facility gets **14 days free** on the tier chosen at onboarding. The Settings → My Plan card shows a "Free trial — N days left" countdown.
- **Expiry / lapse:** when a subscription or license expires, the facility sees a clear **"Your subscription has expired — some modules are locked until you renew"** warning, and the plan card switches to an *Expired* state. Renewing reactivates everything immediately.
- **Upgrade / downgrade:** changing tier takes effect on payment; seat limits and available modules update right away.

---

## 6. Limits that are enforced per tier

The system enforces the "how much you can use" numbers per plan, and the plan card shows live usage (e.g. "1/3 practitioners"):

- **Basic Dental:** 3 practitioners / 3 doctors, 5,000 patients
- **Standard Dental:** 7 practitioners, unlimited doctors & patients
- **Premium Dental:** unlimited everything
- **Hospital plans:** practitioners/doctors/patients are unlimited, but the monthly-visit bands (0–100 / 101–250 / 251+) define the subscription tier

---

## 7. What the super admin can change at any time

Nothing about pricing is hard-coded. From the super admin console, the platform owner can, at any time and without a code deploy:

- Edit any plan's **price** (monthly, yearly, or license price)
- Turn **modules** on/off per plan (which modules the facility sees)
- Turn **feature flags** on/off per plan (billing, HMO interface, full accounting, WhatsApp reminders, etc.)
- Edit **seat limits** (practitioners, doctors, patients)
- Edit **pay-as-you-go rates** per event
- **Activate / archive** plans, set which plan new facilities trial on
- Issue or renew **offline licenses** (1/2/5 years) from a facility's detail page
- View every facility's **payment history** across the platform

The same data drives the whole app — the plan card, the module menu, the premium gates (e.g. the HMO interface only appears on Premium), and the offline license checks — so a pricing change takes effect everywhere at once.

---

## 8. Where customers see this in the app

| Where | What they see |
|---|---|
| Settings → **My Plan** card | Current tier, price, renewal/trial date, status badge, seat usage bars, PAYG usage meter (hospitals), upgrade button |
| Settings → **Upgrade modal** | All plans with live prices, Monthly vs Yearly toggle (dental), license length picker, Paystack checkout |
| Settings → **Offline License** card | License key, expiry countdown, activate-license-file box, online renewal check |
| Super admin console | Full plan catalog editor, per-facility subscriptions & licenses, payment history |

---

## 9. Notes / open questions

- Hospital plans are currently configured as **"both"** (subscription *and* pay-as-you-go) — the product decision on whether PAYG is a supplement or a separate mode is tracked in the billing plan docs.
- Paystack recurring (auto-charge every month) is planned but not yet live; for now renewal is a manual "pay again" flow in the same modal.
