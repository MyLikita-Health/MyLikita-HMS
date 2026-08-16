# Keep-Alive Pharmacy Carts — Implementation Spec

**Status:** Draft for review
**Scope:** Keep the Drug Purchase cart (`AddnewDrug`) and the Drug Sales cart (`DrugSale`)
mounted-but-hidden across pharmacy tab switches, so staff can build both carts at once and
flip between them without losing line items, suppliers, customers, or payment details.

---

## 1. Goal and user story

> A dispensary officer starts a Drug Purchase (supplier, invoice, a few line items), then
> remembers a walk-in customer at the counter. They click **Drug Sales**, serve the
> customer, and click back to **Drug Purchase** — the supplier, invoice number, and all
> item rows are exactly where they left them.

Today that flow loses the purchase cart (and vice-versa) because each tab is a route and
the `<Switch>` unmounts the previous page. This spec adds a keep-alive wrapper so **just
these two forms** stay mounted-hidden; every other pharmacy page keeps its current
mount/unmount behavior.

---

## 2. Current behavior (the problem)

- `AuthenticatedContainer` (`frontend/src/routes/AuthenticatedContainer.jsx`, line ~499)
  mounts `<PharmacyIndex />` at `/me/pharmacy`.
- `PharmacyIndex` (`frontend/src/components/pharmacy/PharmacyIndex.jsx`) renders
  `<PharmacyMenu />` (the live horizontal nav) + `<PharmacyRoute />`.
- `PharmacyRoute` (`frontend/src/components/pharmacy/PharmacyRoute.jsx`) is a `<Switch>`
  of `<PermissionRoute>`s. Navigating tabs = URL change = the `<Switch>` unmounts the
  previous component. All cart state is **local `useState`** (not Redux), so it dies on
  every tab switch:

| Cart | Component | Route (exact) | Cart state (local) | Gate |
|---|---|---|---|---|
| Drug Purchase | `AddnewDrug` — `drug/AddnewDrug.jsx` | `/me/pharmacy/drug-purchase/add-new-purchase` | `rows`, `base` (supplier/store/invoice), `success`, `confirmOpen` | `pharmacyPermissions.canManageInventory` |
| Drug Sales | `DrugSale` — `drug/DrugSales.jsx` | `/me/pharmacy/drug-sales` (nested inside `DrugSalesPage`) | `cart`, `form`, `selectedCustomer`, `otherInfo`, safety/COGS modal state | `pharmacyPermissions.canViewSales` |

### Findings that shape the design

1. **`PharmTabs` is currently dead code.** `PharmTabs` (defined and exported in
   `PharmacyRoute.jsx` lines 66 / 365) is **never imported anywhere** — the live nav is
   `PharmacyMenu`. The wrapper therefore composes around the route content area
   (`PharmacyRoute`'s `<Switch>`), which is where `PharmTabs` would render if revived.
   Reviving `PharmTabs` as the nav (or deleting it) is out of scope; see §9.
2. **React 16.13.1 / react-router-dom 5.3.4 / history 4.x.** `useLocation`, `matchPath`,
   and `history.block(fn)` (function blocker, target-aware) are all available. No
   `StrictMode` in the app, so no double-mount in dev to worry about.
3. **`DrugSale` registers a global keydown listener while mounted**
   (`DrugSales.jsx`: Enter → `addToCart`, F10 → `submitCart`). Once kept alive, it would
   keep firing while hidden — pressing Enter on the purchase tab would add a phantom item
   to the hidden sales cart. **Must be gated on visibility.**
4. **`AddnewDrug` renders `<Prompt when={filledRows.length > 0} message="You have unsaved
   items. Leave anyway?" />`.** Once kept alive, this fires on *every* navigation —
   including the tab switch we are trying to make seamless. The guard must become
   target-aware: allow navigation inside `/me/pharmacy` (carts are preserved), still block
   leaving the pharmacy module (carts are lost on unmount).
5. **A component cannot render in two tree positions and share state.** The kept instance
   must live in exactly one place — a container whose `display` toggles — and the
   matching routes must be **removed from the `<Switch>`** so the router never mounts a
   second copy (which would double-fetch and double-register listeners).
6. **`DrugSalesPage`'s nested exact `<Route>` is not enough.** The sales cart is rendered
   by a nested `<Route path="/me/pharmacy/drug-sales" component={DrugSale} exact />`
   inside `DrugSalesPage`. Keeping `DrugSalesPage` alive would NOT keep `DrugSale` alive:
   once the URL leaves `/drug-sales`, the nested route stops matching and the cart
   unmounts. `DrugSale` must become a **direct child** of `DrugSalesPage` with its own
   visibility toggle.
7. **No remount ⇒ stale lookup data.** Both carts fetch their lookup lists on mount
   (`AddnewDrug`: suppliers, drug registry, stores; `DrugSale`: store sale items, client
   list). With keep-alive these run once; stock can go stale (e.g. a recorded purchase
   changes balances). Spec adds a refresh-on-activate hook (§5.4) that must not clobber
   local cart state.

---

## 3. Architecture overview

```
AuthenticatedContainer (/me/pharmacy)
└── PharmacyIndex
    ├── PharmacyMenu            (nav — unchanged)
    └── PharmKeepAlive          (NEW wrapper — owns the two live carts)
        ├── <div hidden={keptRouteActive}>          layer A
        │   └── <Switch> … </Switch>                kept routes REMOVED
        ├── <div display={purchaseActive}>          layer B
        │   └── <AddnewDrug active={purchaseActive} />
        └── <div display={salesActive}>             layer C
            └── <DrugSalesPage>                     restructured: DrugSale is a
                ├── <PendingPharmacyRequest />        direct child, toggled inside
                └── <DrugSale active={isSalesCartRoute} /> + detail <Route>s
```

- Exactly one of layers A/B/C is visible at a time.
- Layers B and C stay **mounted** from first visit to module exit; their `display` flips.
- The `<Switch>` never renders the two kept routes (removed in §5.2), so there is exactly
  one instance of each cart.
- Leaving `/me/pharmacy` unmounts `PharmacyIndex` → the wrapper and both carts unmount →
  carts are lost; the target-aware unsaved guard (§5.3) warns for the purchase cart first.

---

## 4. New file: `frontend/src/components/pharmacy/PharmKeepAlive.jsx`

### Props

| Prop | Type | Meaning |
|---|---|---|
| `children` | ReactNode | The `<Switch>` from `PharmacyRoute` with the two kept routes removed |

### Visibility predicates

Computed from `useLocation()` inside the wrapper:

| Flag | Path | Match |
|---|---|---|
| `purchaseActive` | `/me/pharmacy/drug-purchase/add-new-purchase` | exact |
| `salesActive` | `/me/pharmacy/drug-sales` | `pathname.startsWith(...)` (covers detail sub-routes) |
| `keptRouteActive` | — | `purchaseActive \|\| salesActive` |

### Render contract

```jsx
<div style={{ display: keptRouteActive ? "none" : "block" }}>{children}</div>

{canManageInventory && (
  <div style={{ display: purchaseActive ? "block" : "none" }}>
    <AddnewDrug active={purchaseActive} />
  </div>
)}

{canViewSales && (
  <div style={{ display: salesActive ? "block" : "none" }}>
    <DrugSalesPage />
  </div>
)}
```

Notes:

- **Permission gates mirror the removed routes** — reuse the same `canShow(...)` helper
  (currently module-local in `PharmacyRoute.jsx`; export it from there or move it to
  `frontend/src/utils/permissionHelper.js` so both files share one copy). If the user
  lacks the permission, the cart is never mounted (matches today: the `PermissionRoute`
  rendered nothing).
- **Never unmount layers B/C while inside the module.** Mounting order and container
  position must be stable so React preserves the instances (no keys, no conditional
  short-circuit that removes the container from the tree).
- Hidden containers use `display: none` (not `visibility: hidden`) so hidden inputs leave
  the tab order and the accessibility tree automatically.
- Optional: `window.scrollTo(0, 0)` on layer activate, to match fresh-page behavior.

---

## 5. Changes to existing files

### 5.1 `PharmacyRoute.jsx` — compose the wrapper, drop the kept routes

1. Wrap the `<Switch>`: `return <PharmKeepAlive><Switch>…</Switch></PharmKeepAlive>;`
2. **Remove** the purchase route:
   ```jsx
   <PermissionRoute path="/me/pharmacy/drug-purchase/add-new-purchase"
                    component={AddnewDrug} exact
                    permission={pharmacyPermissions.canManageInventory} />
   ```
3. **Remove** the sales route:
   ```jsx
   <PermissionRoute path="/me/pharmacy/drug-sales"
                    component={DrugSalesPage}
                    permission={pharmacyPermissions.canViewSales} />
   ```
4. Leave `PharmTabs` untouched (dead code; see §9). Leave every other route untouched —
   they keep today's mount/unmount behavior.

### 5.2 `drug/DrugSalesPage.jsx` — make `DrugSale` a direct child

Replace the nested-route cart with a direct child whose visibility is toggled; keep the
detail routes:

```jsx
function DrugSalesPage() {
  const location = useLocation();
  const isCartRoute = location.pathname === "/me/pharmacy/drug-sales";

  return (
    <div style={{ display: "flex", gap: 10, padding: "10px 12px", background: "#f0f4ff",
                  minHeight: "100vh", alignItems: "flex-start", boxSizing: "border-box" }}>
      <div style={{ width: 260, flexShrink: 0 }}>
        <PendingPharmacyRequest />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: isCartRoute ? "block" : "none" }}>
          <DrugSale active={isCartRoute} />
        </div>
        {!isCartRoute && (
          <>
            <Route path="/me/pharmacy/drug-sales/pending-dispensery/:patientId"
                   component={PendingDrugDispensery} exact />
            <Route path="/me/pharmacy/drug-sales/view/:patientId"
                   component={PendingDrugSale} />
          </>
        )}
      </div>
    </div>
  );
}
```

Behavioral consequence (intentional): today, drilling into a patient detail page
unmounts the cart; with this change the cart survives a drill-in and back. That is the
same "live cart" guarantee the tab switch provides, and is desirable.

### 5.3 `drug/AddnewDrug.jsx` — `active` prop + target-aware unsaved guard

1. Accept `active = false` as a prop (default `false` keeps the existing test harness
   working).
2. **Remove the `<Prompt>`** (and its import). Replace the naive all-navigation guard with
   the wrapper-owned `history.block` (§5.3.1) so tab switches are free but module exit is
   still warned.
3. **Dirty signal:** expose the purchase cart's dirtiness to the wrapper so the guard
   knows when to engage. Two options:
   - (a) the wrapper passes a ref/callback down, or
   - (b) simplest: the wrapper itself tracks `purchaseActive` and the wrapper re-renders on
     cart changes via a registered `onDirtyChange(Boolean)` callback from `AddnewDrug`
     (called from an effect on `filledRows.length`).
   The spec recommends (b): `AddnewDrug` calls `onDirtyChange(filledRows.length > 0)`
   in an effect; the wrapper stores it in state.

#### 5.3.1 Wrapper-owned target-aware guard (in `PharmKeepAlive.jsx`)

```js
const history = useHistory();
useEffect(() => {
  if (!purchaseDirty) return;                 // nothing to guard
  const unblock = history.block((next) => {
    // Allow every navigation that keeps the module (and therefore the carts) mounted.
    if (next.pathname.startsWith("/me/pharmacy")) return true;
    // Leaving the module unmounts the wrapper -> purchase cart is lost.
    return "You have unsaved purchase items. Leave anyway?";
  });
  return unblock;
}, [history, purchaseDirty]);
```

- history 4.x function blockers: return `true` to allow, a string to confirm, `false`/
  `undefined`… to block silently. `return true` is the explicit allow.
- Because the guard is keyed on `purchaseDirty`, it is inert until the user actually
  starts a cart — same as today's `<Prompt when={filledRows.length > 0}>`.
- The sales cart has no unsaved guard today; keep-alive preserves it, so none is added.

### 5.4 `drug/DrugSales.jsx` — `active` prop, gate the keydown listener, refresh on activate

1. Accept `active = false` as a prop.
2. **Gate the global keydown listener** (this is the critical one):
   ```js
   useEffect(() => {
     if (!active) return;
     document.addEventListener("keydown", handleKeyPress);
     return () => document.removeEventListener("keydown", handleKeyPress);
   }, [active, handleKeyPress]);
   ```
3. **Refresh on activate** (recommended, optional in v1): refetch lookups when the cart
   becomes visible again so stock isn't stale after a purchase was recorded:
   ```js
   useEffect(() => {
     if (active) {
       dispatch(getSalesDrugs(form.store_name, 0, 100));
       dispatch(getClientInfo());
     }
   }, [active, dispatch, form.store_name]);
   ```
   Keep the deps tight; never touch `cart`/`form`/`otherInfo` in the refresh — only the
   Redux lookup data (`saleItems`, `clientInfo`), which the cart already reads reactively.

### 5.5 `drug/AddnewDrug.jsx` — refresh on activate (recommended)

Same pattern: on `active` flip to true, re-dispatch `getSupplierInfo()`,
`getAllDrugs(setDrugs)`, `getPharmStore()`. **Do not** re-run the mount effect's
`setBase(p => ({ ...p, receivedTo: store }))` — that would overwrite a store the user
already picked; only set `receivedTo` on refresh if it is still empty.

---

## 6. Edge cases and behavioral notes

| Case | Behavior |
|---|---|
| User never visits a cart tab | Layers B/C never mount — zero cost until first visit |
| No permission for a cart | That layer is never mounted; behavior identical to today's empty `PermissionRoute` |
| Tab switch with a full cart | No prompt; cart intact on return (the whole point) |
| Leaving `/me/pharmacy` with dirty purchase rows | `history.block` warns first (state will be lost) |
| Enter/F10 pressed while sales cart hidden | Listener not attached — no phantom items |
| Purchase recorded (`success` screen) then tab away/back | Success screen persists — acceptable, arguably good ("Purchase Recorded!" still shown) |
| Deep-link straight to `/add-new-purchase` | Mounts once; "Back to Inventory" (`history.goBack()`) may leave the app — replace with an explicit `history.push("/me/pharmacy/drug-purchase?type=with-alert")` (recommended, optional) |
| Detail drill-in from sales sidebar | Cart survives (see §5.2) — intentional improvement |
| Stale stock after recording a purchase | Refresh-on-activate (§5.4/§5.5) |
| Duplicate mounts / double fetches | Impossible by construction: kept routes are removed from the `<Switch>` |

---

## 7. Testing plan (vitest + @testing-library/react, matching `AddnewDrug.test.jsx`)

New `frontend/src/components/pharmacy/PharmKeepAlive.test.jsx`:

1. **State survives tab switches** — render the wrapper (with a stubbed `Switch`) inside
   `MemoryRouter`; add an item to the sales cart; navigate to the purchase route; navigate
   back; assert the cart item is still rendered and the mocked fetch actions did **not**
   re-run (mount once).
2. **Purchase rows survive** — enter purchase rows, switch to sales, switch back, assert
   rows intact and the supplier/invoice values unchanged.
3. **Hidden keydown is inert** — with the sales cart hidden, `fireEvent.keyDown(document,
   { key: "Enter" })` adds nothing; with it visible, Enter adds an item.
4. **Prompt semantics** — dirty purchase cart + navigation to `/me/doctor` triggers the
   block message; dirty + navigation to `/me/pharmacy/drug-sales` does not.
5. **Permissions** — mock the permission helper: without `canManageInventory`/
   `canViewSales` the hidden layers never mount (fetch actions never fire).
6. **Double-mount guard** — mount once, flip routes several times, assert each cart's
   mount-only fetch ran exactly once.

Update existing tests:

- `AddnewDrug.test.jsx`: the `Prompt: () => null` mock (in the `react-router` mock) can be
  dropped or kept; add an `active` prop assertion if desired (default `false` keeps the
  suite green).
- `DrugSales.test.jsx`: same — default `active` keeps it green; add a case that the
  keydown listener is absent when `active={false}`.

Manual QA on the running app (vite dev on :5176 per `.freebuff/run.md`, backend via
relay): build a purchase cart, flip to Drug Sales, complete a small sale, flip back —
purchase rows, supplier, and invoice amount must all persist.

---

## 8. Implementation checklist (ordered)

1. Export/share the `canShow` permission helper (`PharmacyRoute.jsx` →
   `permissionHelper.js` or export from `PharmacyRoute`).
2. Create `PharmKeepAlive.jsx` (layers, predicates, permissions, `history.block` guard,
   optional scroll-to-top).
3. `PharmacyRoute.jsx`: wrap the `<Switch>`, delete the two kept routes.
4. `DrugSalesPage.jsx`: direct-child `DrugSale` with display toggle (§5.2).
5. `AddnewDrug.jsx`: `active` prop, remove `<Prompt>`, `onDirtyChange` signal, optional
   refresh-on-activate (§5.5).
6. `DrugSales.jsx`: `active` prop, gated keydown listener, optional refresh-on-activate
   (§5.4).
7. Tests (§7) + `npm run test` (or the repo's frontend test command) green.
8. Manual QA of the two-cart flow.

---

## 9. Out of scope / decisions for the reviewer

- **`PharmTabs` is dead code.** Either revive it as the pharmacy nav (it already has the
  tab list + permission filtering; the wrapper composes around the same content area) or
  delete it. This spec does neither — it composes at `PharmacyRoute`, the content area
  `PharmTabs` would live beside. Confirm the intended direction.
- **State-lifting alternative (not chosen):** move `rows`/`cart`/`base` into the
  pharmacy Redux slice so remounts are cheap. Rejected because the request is explicitly
  a mounted-hidden keep-alive, and because both forms carry non-serializable transient
  state (dropdown open flags, refs, modal state) that is painful to lift.
- **Third-party keep-alive libs** (e.g. `react-activation`): not used in the project;
  per convention, hand-rolled wrapper wins.
- **Dirty-cart badges** on the `PharmacyMenu` items (e.g. "2 items" on Drug Sales while
  hidden): natural phase-2 extension; the `onDirtyChange` signal in §5.3 already exists
  for it.
