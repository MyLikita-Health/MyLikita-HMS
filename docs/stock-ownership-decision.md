# Stock Ownership — Integration Decision

**Status:** Decision (recommendation ready for implementation review)
**Scope:** Pharmacy module (`drugs`, `pharm_store`, `pharm_store_entries`) × Inventory module (`inventory_items`, `inventory_stock`, `inventory_batches`, `inventory_transactions`)
**Question:** Does the pharmacy module work with the inventory module, or are they separate systems?

---

## 1. The problem

Two independent stock engines exist today:

| | **Pharmacy (drugs)** | **Inventory (generic)** |
|---|---|---|
| Catalog | `drugs` — flat: `drug_code`, `drug`, `price`, `markup`, `expiry_date`, `supplier`, `source` | `inventory_items` — item master: `item_code`, `barcode`, `item_name`, `category`, `unit_of_measure`, reorder levels, **GL account heads (`cogs_account`, `adjustment_account`)** |
| Balance | `pharm_store` — one row per **batch × store** (`item_code`, `store`, `expiry_date`, `price`), `balance` column | `inventory_stock` — one row per **item × location**, with `quantity_on_hand`, `quantity_reserved`, `quantity_available`, min/max |
| Ledger | `pharm_store_entries` — `qty_in`/`qty_out`, `unit_price`, **`cost_price` + `cogs_source`** (captured at insert), `sales_type`, `item_status`, `patient_id`, `inserted_by` | `inventory_transactions` — typed (`purchase/issue/return/adjustment/transfer/disposal/stock_take`), `unit_cost`/`total_cost`, `from/to_location`, `performed_by`/`approved_by`, `journal_entry_id`, `posted_to_accounts` |
| Locations | `store` (string on rows) | `inventory_locations` — typed locations, **`location_type` already includes `'pharmacy'`** |
| Strengths | Mature, battle-tested drug logic: FEFO POS with COGS at insert, returns restoring batches, stocktakes + reconciliation, batch P&L, controlled-drugs register, expiry alerts, ~800 backend tests | Generic, multi-department, catalog + accounting-head driven, PO/GRN/requisitions/issue/forecasting/expiry/reorder tooling, barcodes |

**Verified: there is zero integration glue.** No pharmacy controller references `inventory_*` tables; no inventory controller references `pharm_*`/`drugs`. A facility cannot see its drug stock and its consumables in one view, cannot raise one purchase order covering both, and cannot get one COGS/GL picture. The inventory module is already being used for exactly the non-drug items the user described (`CON-0001 Toilet Cleaners`, `OFF-0001 Printed Receipt Papers`).

For a simple clinic, pharmacy alone is enough. For a larger hospital with departmental stock (consumables, equipment, reagents), the two must share *identity and accounting* while keeping *their own ledgers*.

---

## 2. The four integration paths

### Path 1 — Two silos (status quo)
Keep both engines completely independent. Pharmacy handles drugs; inventory handles everything else. Users re-enter the same supplier, item, and receipt in two places.

- **Pros:** zero migration risk; nothing touches the proven pharmacy engine.
- **Cons:** duplicate catalogs and PO/GRN flows; no cross-department stock visibility; no single COGS/margin view; a drug purchased through the hospital receiving dock never reaches the pharmacy counter; controlled-drugs compliance only enforceable in one module.
- **Risk:** low · **Effort:** none · **Fit for large hospitals:** poor

### Path 2 — Full unification (inventory subsumes pharmacy)
Make `inventory_items`/`inventory_stock`/`inventory_batches`/`inventory_transactions` the single engine. Drugs become `item_type='drug'` items; the pharmacy POS, dispensary, and controlled-drugs register read/write inventory tables; `pharm_store`/`pharm_store_entries` retire.

- **Pros:** one engine, one catalog, one ledger, one accounting story — the textbook end state.
- **Cons:** re-plumbing everything the pharmacy already does well (FEFO sale proc with COGS capture, returns restoring batch + COGS, stocktake reconciliation, batch P&L, controlled-drugs register) onto different tables is months of work with high regression risk to a system that currently passes ~800 tests; `inventory_stock` has no batch-level balance concept (batches hold `quantity`, stock holds the aggregate), so FEFO dispense and per-batch COGS must be rebuilt; legacy stored procedures would need a rewrite.
- **Risk:** high · **Effort:** very high · **Fit:** conceptually cleanest, practically the riskiest

### Path 3 — Pharmacy absorbs inventory
Extend `pharm_store`/`pharm_store_entries` to non-drug items (equipment, reagents, consumables).

- **Pros:** smallest schema change; pharmacy's ledger machinery (COGS, returns, reconciliation) applies everywhere.
- **Cons:** forces drug-specific baggage (expiry-driven FEFO, markup, schedules) onto items that don't need it; `pharm_store` has no reserved quantity, no typed locations, no item master with GL account heads; the inventory module's catalog/reporting work is thrown away.
- **Risk:** medium · **Effort:** medium · **Fit:** poor — it under-serves the hospital case it's meant to fix

### Path 4 — Federated stock, shared item master *(chosen)*
One canonical item catalog (`inventory_items` extended with `item_type`/`managed_by`); each domain keeps the ledger it is best at. A thin ownership registry maps a canonical item to its authoritative ledger, and a movement bridge correlates any movement that touches the "other" ledger (e.g. a receiving-dock GRN that includes both drugs and consumables). Views unify reporting.

- **Pros:** the pharmacy engine is untouched (no regression to proven logic); the inventory module gets drugs as first-class items for catalog/accounting; one PO can cover drugs + consumables; per-item ownership is facility-configurable, so a simple clinic can stay pharmacy-only while a large hospital runs the full mix; incremental phases.
- **Cons:** two ledgers to reconcile (the bridge exists precisely to make that auditable); more moving parts than Path 2's end state.
- **Risk:** low · **Effort:** medium · **Fit:** best

---

## 3. Decision criteria

| Criterion | Path 1 silos | Path 2 unified | Path 3 pharm-first | **Path 4 federated** |
|---|---|---|---|---|
| Regression risk to proven pharmacy logic | none | **high** | medium | **low** |
| One catalog for drugs + consumables | ✗ | ✓ | partial | **✓** |
| One PO/GRN covering both | ✗ | ✓ | ✗ | **✓ (via bridge)** |
| Single GL / COGS picture | ✗ | ✓ | partial | **✓ (via views + bridge)** |
| Controlled-substances compliance | pharm only | rebuild | ✓ | **✓ (unchanged)** |
| Batch FEFO + per-batch COGS | ✓ (pharm) | **rebuild** | ✓ | **✓ (unchanged)** |
| Multi-department (non-drug) stock | inventory only | ✓ | ✗ | **✓ (inventory)** |
| Simple clinic can ignore inventory | ✓ | forced | ✗ | **✓ (configurable)** |
| Time to value | — | months | weeks | **weeks (phased)** |

**Recommendation: Path 4.** It buys the one thing the hospital case actually needs — shared item identity and accounting with per-item ownership — without rewriting the pharmacy engine that already does FEFO, COGS, returns, stocktakes, and the controlled-drugs register correctly.

---

## 4. Concrete schema for the chosen path (Path 4)

Design principles: the inventory module owns the **catalog**; a `managed_by` flag owns **which ledger** is authoritative per item; the bridge owns **cross-engine movements**; nothing existing is dropped.

### 4.1 Item master — extend `inventory_items`

```sql
ALTER TABLE inventory_items
  ADD COLUMN item_type     ENUM('drug','consumable','equipment','reagent','lab_supply','other')
                             NOT NULL DEFAULT 'other' AFTER sub_category,
  ADD COLUMN managed_by    ENUM('pharmacy','inventory')
                             NOT NULL DEFAULT 'inventory' AFTER item_type,
  ADD COLUMN generic_name  VARCHAR(150) NULL AFTER item_name,
  ADD COLUMN strength      VARCHAR(50)  NULL AFTER generic_name,   -- e.g. '500mg'
  ADD COLUMN dosage_form   VARCHAR(50)  NULL AFTER strength,       -- e.g. 'Tablet'
  ADD COLUMN schedule_class VARCHAR(10) NULL,                      -- 'I'..'V' / NULL for non-drugs
  ADD COLUMN is_controlled TINYINT(1)   NOT NULL DEFAULT 0,
  ADD COLUMN markup_pct    DECIMAL(5,2) NULL,                      -- pharmacy margin; NULL = sell at cost
  ADD UNIQUE KEY uq_item_code_fac (facilityId, item_code);

-- Ownership rule (enforced in service layer, documented here):
--   item_type = 'drug'            → managed_by = 'pharmacy' (authoritative ledger: pharm_store)
--   item_type in (consumable, equipment, reagent, lab_supply, other)
--                                 → managed_by = 'inventory' (authoritative ledger: inventory_stock)
-- A facility can override managed_by for edge cases (e.g. ward drug cupboards kept in inventory).
```

### 4.2 Ownership registry — link canonical item ↔ ledger key

```sql
CREATE TABLE stock_item_links (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id   VARCHAR(50)  NOT NULL,
  item_id       INT          NOT NULL,             -- inventory_items.id (canonical)
  owner_module  ENUM('pharmacy','inventory') NOT NULL,
  owner_key     VARCHAR(60)  NOT NULL,             -- pharm_store.item_code (drugs) | inventory_items.item_code
  is_primary    TINYINT(1)   NOT NULL DEFAULT 1,   -- which ledger the balance is read from
  created_by    VARCHAR(100) NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_owner (facility_id, owner_module, owner_key),
  KEY idx_item (facility_id, item_id),
  CONSTRAINT fk_sil_item FOREIGN KEY (item_id) REFERENCES inventory_items (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

**Behavior:** when a drug is created in the pharmacy module, the service creates (or finds) the `inventory_items` row with `item_type='drug', managed_by='pharmacy'` and a `stock_item_links` row pointing at the existing `pharm_store.item_code`. The pharmacy keeps working exactly as today; the item master is now queryable by the whole facility. When a non-drug is created in inventory, no link is needed (owner_key = its own item_code is implied).

### 4.3 Movement bridge — cross-engine correlation

One receiving dock / one purchase order may cover both drugs and consumables. The bridge records the single real-world movement and which ledger each leg landed in, so reconciliation is a join, not a guess.

```sql
CREATE TABLE stock_movement_bridge (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  movement_uuid  CHAR(36)     NOT NULL,            -- shared correlation id generated by the caller
  facility_id    VARCHAR(50)  NOT NULL,
  item_id        INT          NOT NULL,
  movement_type  ENUM('purchase','grn','issue','transfer','adjustment',
                      'return','stock_take','sale','dispense') NOT NULL,
  source_ledger  ENUM('pharmacy','inventory') NOT NULL,   -- ledger the movement originated in
  dest_ledger    ENUM('pharmacy','inventory') NOT NULL,   -- ledger that must also be updated
  quantity       INT          NOT NULL,
  unit_cost      DECIMAL(12,2) NULL,
  reference_type VARCHAR(40)  NOT NULL,            -- 'pharm_store_entries.version_id' | 'inventory_transactions.id' | 'po_no' | 'grn_no'
  reference_id   VARCHAR(100) NOT NULL,            -- the row in the destination ledger
  status         ENUM('pending','applied','failed') NOT NULL DEFAULT 'pending',
  error          VARCHAR(500) NULL,
  created_by     VARCHAR(100) NULL,
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_movement_leg (movement_uuid, source_ledger, dest_ledger, item_id),
  KEY idx_ref (facility_id, reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

**Worked example — hospital GRN that includes drugs and consumables:**

1. The receiving dock scans the PO. Inventory service posts consumables to `inventory_transactions` (type `grn`) and `inventory_stock` as it does today.
2. For each line whose `stock_item_links.owner_module='pharmacy'`, the same transaction inserts the `pharm_store_entries` purchase row (with `cost_price`, `cogs_source='fefo-store'`, `sales_type='Purchase Order'`), bumps `pharm_store.balance`, and writes one bridge row with `movement_uuid` shared across all legs.
3. GL posting is unchanged on both sides — each ledger already posts its own journals; the bridge carries `reference_id` so an auditor can walk from the inventory entry to the pharmacy entry for the same physical receipt.

**Worked example — pharmacy dispense of a drug that arrived via inventory:** `source_ledger='inventory'`, `dest_ledger='pharmacy'`? No — the drug's authoritative ledger is pharmacy, so dispenses never leave the pharmacy engine; the bridge is only for movements *into* a ledger from outside it (receiving) or *out of* one (departmental issue/transfer of a drug from an inventory-managed ward cupboard). Ownership decides direction; the bridge makes the decision visible.

### 4.4 Parity view — one reconciliation query

```sql
CREATE OR REPLACE VIEW vw_ledger_parity AS
SELECT
  l.facility_id,
  l.item_id,
  i.item_code,
  i.item_name,
  i.item_type,
  i.managed_by,
  -- Pharmacy ledger (authoritative for drugs)
  COALESCE((SELECT SUM(CAST(pse.qty_in AS SIGNED)) - SUM(CAST(pse.qty_out AS SIGNED))
              FROM pharm_store_entries pse
              JOIN pharm_store ps ON ps.item_code = pse.item_code AND ps.facilityId = pse.facilityId
             WHERE pse.item_code = l.owner_key AND pse.facilityId = l.facility_id), 0) AS pharm_qty,
  -- Inventory ledger (authoritative for non-drugs)
  COALESCE((SELECT SUM(b.quantity) FROM inventory_batches b
             WHERE b.item_id = l.item_id AND b.facilityId = l.facility_id), 0) AS inventory_qty,
  (SELECT COUNT(*) FROM stock_movement_bridge smb
    WHERE smb.item_id = l.item_id AND smb.facilityId = l.facility_id
      AND smb.status = 'failed') AS bridge_failures
FROM stock_item_links l
JOIN inventory_items i ON i.id = l.item_id;
```

Any row where the authoritative ledger's quantity disagrees with the other ledger's (for dual-managed items) or where `bridge_failures > 0` is a stock-ownership defect to investigate — surfaced on the inventory dashboard and the pharmacy reconciliation report.

---

## 5. Implementation phases

1. **Phase 1 — Shared catalog (weeks).** Migration above; item creation from either module writes `inventory_items` + `stock_item_links`; the pharmacy drug picker gains an "also visible in inventory" catalog entry; `managed_by` configurable per item by admins.
2. **Phase 2 — The bridge (weeks).** PO/GRN services post cross-owned lines to both ledgers in one transaction with `movement_uuid`; requisition/issue of a drug from an inventory-managed location posts the pharmacy leg; `vw_ledger_parity` + a dashboard alert on bridge failures.
3. **Phase 3 — Unified reporting (weeks).** One stock-value view (`inventory_stock` + `pharm_store` joined through the links), one COGS/GL view, one expiry view; keep per-module reports intact.

**Explicitly out of scope (do not do):** migrating `pharm_store`/`pharm_store_entries` onto inventory tables (Path 2), and adding drug-specific columns to `inventory_items` beyond the minimal `item_type`/schedule fields — dosage, interaction, and schedule enforcement stay in the pharmacy/MMI domain.

---

## 6. Decision summary

- **Do not** keep the silos (Path 1) if the facility has any non-drug departmental stock.
- **Do not** unify onto one engine (Path 2) or extend pharmacy to everything (Path 3) — both risk the proven pharmacy logic or force drug baggage onto everything.
- **Do** federate (Path 4): one item master, per-item ledger ownership, a movement bridge for cross-ownership receipts, and parity views for a single GL/COGS picture. Simple clinics configure `managed_by='pharmacy'` and never see inventory; large hospitals get drugs, consumables, equipment, and reagents in one catalog with auditable per-ledger truth.
