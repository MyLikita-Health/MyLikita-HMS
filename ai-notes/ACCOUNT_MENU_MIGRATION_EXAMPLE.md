# AccountMenu Migration Example

This document shows how to migrate `AccountMenu.jsx` from the legacy permission system to the new granular permissions system.

---

## Current Implementation (Legacy)

```javascript
import { canUseThis } from "../auth";

{user.accessTo
  ? canUseThis(user, ["Record Expenses"]) && (
    <ListMenuItem route="/me/account/expenditure">
      Record Expenses
    </ListMenuItem>
  )
  : null}
```

---

## New Implementation (Granular)

```javascript
import { billingPermissions } from "../../utils/permissionHelper";

{billingPermissions.canCreateExpenses() && (
  <ListMenuItem route="/me/account/expenditure">
    <GiChart size={26} style={{ marginRight: 10 }} />
    Record Expenses
  </ListMenuItem>
)}
```

---

## Complete Migration

### Step 1: Add Import

```javascript
import { billingPermissions } from "../../utils/permissionHelper";
```

### Step 2: Replace Each Menu Item

#### Other Incomes
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Other Incomes"]) && (
  <ListMenuItem route="/me/account/services">
    Other Incomes
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewServices() && (
  <ListMenuItem route="/me/account/services">
    <FaAmazonPay size={26} style={{ marginRight: 10 }} />
    Other Incomes
  </ListMenuItem>
)}
```

#### Reprint Receipt
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Other Incomes"]) && (
  <ListMenuItem route="/me/account/reprint">
    Reprint Receipt
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewBills() && (
  <ListMenuItem route="/me/account/reprint">
    <FaReceipt size={26} style={{ marginRight: 10 }} />
    Reprint Receipt
  </ListMenuItem>
)}
```

#### Record Expenses
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Record Expenses"]) && (
  <ListMenuItem route="/me/account/expenditure">
    Record Expenses
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreateExpenses() && (
  <ListMenuItem route="/me/account/expenditure">
    <GiChart size={26} style={{ marginRight: 10 }} />
    Record Expenses
  </ListMenuItem>
)}
```

#### Make Deposit
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Make Deposit"]) && (
  <ListMenuItem route="/me/account/deposit">
    Make Deposit
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreateDeposits() && (
  <ListMenuItem route="/me/account/deposit">
    <GiPayMoney size={26} style={{ marginRight: 10 }} />
    Make Deposit
  </ListMenuItem>
)}
```

#### Create Client Account
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Create a Client Account"]) && (
  <ListMenuItem route="/me/account/new-client">
    Create a Client Account
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreateAccounts() && (
  <ListMenuItem route="/me/account/new-client">
    <FaUserPlus size={26} style={{ marginRight: 10 }} />
    Create a Client Account
  </ListMenuItem>
)}
```

#### Generate Account Report
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Generate Account Report"]) && (
  <ListMenuItem route="/me/account/report">
    Generate Account Report
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewReports() && (
  <ListMenuItem route="/me/account/report">
    <IoIosPaper size={26} style={{ marginRight: 10 }} />
    Generate Account Report
  </ListMenuItem>
)}
```

#### Financial Reports
```javascript
// Always visible (or add permission check)
<ListMenuItem route="/me/account/financial-reports">
  <FiFileText size={26} style={{ marginRight: 10 }} />
  Financial Reports
</ListMenuItem>

// Or with permission
{billingPermissions.canViewReports() && (
  <ListMenuItem route="/me/account/financial-reports">
    <FiFileText size={26} style={{ marginRight: 10 }} />
    Financial Reports
  </ListMenuItem>
)}
```

#### Retainership Management
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Retainership Management"]) && (
  <ListMenuItem route="/me/account/retainership">
    Retainership Management
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewRetainership() && (
  <ListMenuItem route="/me/account/retainership">
    <FaHandshake size={26} style={{ marginRight: 10 }} />
    Retainership Management
  </ListMenuItem>
)}
```

#### Record Retainership Deposit
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Record Retainership Deposit"]) && (
  <ListMenuItem route="/me/account/retainership-deposit">
    Record Retainership Deposit
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreateDeposits() && (
  <ListMenuItem route="/me/account/retainership-deposit">
    <FaMoneyBillWave size={26} style={{ marginRight: 10 }} />
    Record Retainership Deposit
  </ListMenuItem>
)}
```

#### Process Retainership Refund
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Process Retainership Refund"]) && (
  <ListMenuItem route="/me/account/retainership-refund">
    Process Retainership Refund
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreateRefunds() && (
  <ListMenuItem route="/me/account/retainership-refund">
    <FaUndo size={26} style={{ marginRight: 10 }} />
    Process Retainership Refund
  </ListMenuItem>
)}
```

#### Balance Reconciliation
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Balance Reconciliation"]) && (
  <ListMenuItem route="/me/account/balance-reconciliation">
    Balance Reconciliation
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewReconciliation() && (
  <ListMenuItem route="/me/account/balance-reconciliation">
    <FaBalanceScale size={26} style={{ marginRight: 10 }} />
    Balance Reconciliation
  </ListMenuItem>
)}
```

#### Account Statement
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Account Statement"]) && (
  <ListMenuItem route="/me/account/client-statement">
    Account Statement
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewAccounts() && (
  <ListMenuItem route="/me/account/client-statement">
    <GoNote size={26} style={{ marginRight: 10 }} />
    Account Statement
  </ListMenuItem>
)}
```

#### Cashier Page (Account Review)
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Account Review"]) && (
  <ListMenuItem route="/me/account/review/opd-service?tab=OPD%20Services">
    Cashier Page
  </ListMenuItem>
) : null}

// After
{billingPermissions.canCreatePayments() && (
  <ListMenuItem route="/me/account/review/opd-service?tab=OPD%20Services">
    <FaAddressCard size={26} style={{ marginRight: 10 }} />
    Cashier Page
  </ListMenuItem>
)}
```

#### Create/Edit Services
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Create/Edit Services"]) && (
  <ListMenuItem route="/me/account/setup-services">
    Click to Create/Edit Services
  </ListMenuItem>
) : null}

// After
{billingPermissions.canEditServices() && (
  <ListMenuItem route="/me/account/setup-services">
    <AiOutlineEdit size={26} style={{ marginRight: 10 }} />
    Click to Create/Edit Services
  </ListMenuItem>
)}
```

#### Setup Account Chart
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Setup Account Chart"]) && (
  <ListMenuItem route="/me/account/chart">
    Setup Account Chart
  </ListMenuItem>
) : null}

// After
{billingPermissions.canEditAccountChart() && (
  <ListMenuItem route="/me/account/chart">
    <AiOutlineBranches size={26} style={{ marginRight: 10 }} />
    Setup Account Chart
  </ListMenuItem>
)}
```

#### Managed Care Settings
```javascript
// Before
{user.accessTo ? canUseThis(user, ["Managed Care Settings"]) && (
  <ListMenuItem route="/me/account/managed-care">
    Managed Care Settings
  </ListMenuItem>
) : null}

// After
{billingPermissions.canViewManagedCare() && (
  <ListMenuItem route="/me/account/managed-care">
    <FaHospital size={26} style={{ marginRight: 10 }} />
    Managed Care Settings
  </ListMenuItem>
)}
```

---

## Complete Migrated Component

```javascript
import React, { useEffect } from "react";
import VerticalMenu from "../comp/components/vertical-menu/VerticalMenu";
import ListMenuItem from "../comp/components/vertical-menu/ListMenuItem";
import {
  FaAmazonPay,
  FaUserPlus,
  FaAddressCard,
  FaReceipt,
  FaMoneyBillWave,
  FaUndo,
  FaBalanceScale,
  FaHandshake,
  FaHospital,
} from "react-icons/fa";
import { GiPayMoney, GiChart } from "react-icons/gi";
import { IoIosPaper } from "react-icons/io";
import { GoNote } from "react-icons/go";
import { AiOutlineEdit, AiOutlineBranches, AiOutlineFileDone } from "react-icons/ai";
import { FiFileText } from "react-icons/fi";
import { useDispatch, useSelector } from "react-redux";
import { billingPermissions } from "../../utils/permissionHelper";
import {
  getPendingDiscount,
  getPendingPartPayments,
} from "../../redux/actions/account";
import { Badge } from "reactstrap";
import { BsFillBarChartFill, BsFillAwardFill } from "react-icons/bs";
import { MdBugReport } from "react-icons/md";

const AccountMenu = () => {
  const pendingList = useSelector((state) => state.account.pendingDiscountRequests);
  const pendingPartPayment = useSelector((state) => state.account.pendingPartPayment);
  const dispatch = useDispatch();

  const pendingPartPaymentCount = pendingPartPayment.length;

  useEffect(() => {
    dispatch(getPendingDiscount());
    dispatch(getPendingPartPayments());

    let refresh = setInterval(() => {
      dispatch(getPendingDiscount());
      dispatch(getPendingPartPayments());
    }, 20000);

    return () => {
      clearInterval(refresh);
    };
  }, [dispatch]);

  return (
    <VerticalMenu title="What would you like to do?">
      {billingPermissions.canViewServices() && (
        <ListMenuItem route="/me/account/services">
          <FaAmazonPay size={26} style={{ marginRight: 10 }} />
          Other Incomes
        </ListMenuItem>
      )}

      {billingPermissions.canViewBills() && (
        <ListMenuItem route="/me/account/reprint">
          <FaReceipt size={26} style={{ marginRight: 10 }} />
          Reprint Receipt
        </ListMenuItem>
      )}

      {billingPermissions.canViewBills() && (
        <ListMenuItem route="/me/account/Bills">
          <FaReceipt size={26} style={{ marginRight: 10 }} />
          Pending Bills
        </ListMenuItem>
      )}

      {billingPermissions.canViewPayments() && (
        <ListMenuItem route="/me/account/pending-payments">
          <AiOutlineFileDone size={26} style={{ marginRight: 10 }} />
          Part Payment Transactions{" "}
          {pendingPartPaymentCount > 0 && (
            <Badge color="warning" size="lg">
              {pendingPartPaymentCount}
            </Badge>
          )}
        </ListMenuItem>
      )}

      {billingPermissions.canCreateExpenses() && (
        <ListMenuItem route="/me/account/expenditure">
          <GiChart size={26} style={{ marginRight: 10 }} />
          Record Expenses
        </ListMenuItem>
      )}

      {billingPermissions.canCreateDeposits() && (
        <ListMenuItem route="/me/account/deposit">
          <GiPayMoney size={26} style={{ marginRight: 10 }} />
          Make Deposit
        </ListMenuItem>
      )}

      {billingPermissions.canCreateAccounts() && (
        <ListMenuItem route="/me/account/new-client">
          <FaUserPlus size={26} style={{ marginRight: 10 }} />
          Create a Client Account
        </ListMenuItem>
      )}

      {billingPermissions.canViewReports() && (
        <ListMenuItem route="/me/account/report">
          <IoIosPaper size={26} style={{ marginRight: 10 }} />
          Generate Account Report
        </ListMenuItem>
      )}

      <ListMenuItem route="/me/account/hmo-patient-report">
        <MdBugReport size={26} style={{ marginRight: 10 }} />
        HMO Patient Report
      </ListMenuItem>

      {billingPermissions.canViewReports() && (
        <ListMenuItem route="/me/account/financial-reports">
          <FiFileText size={26} style={{ marginRight: 10 }} />
          Financial Reports
        </ListMenuItem>
      )}

      {billingPermissions.canViewRetainership() && (
        <ListMenuItem route="/me/account/retainership">
          <FaHandshake size={26} style={{ marginRight: 10 }} />
          Retainership Management
        </ListMenuItem>
      )}

      {billingPermissions.canCreateDeposits() && (
        <ListMenuItem route="/me/account/retainership-deposit">
          <FaMoneyBillWave size={26} style={{ marginRight: 10 }} />
          Record Retainership Deposit
        </ListMenuItem>
      )}

      {billingPermissions.canCreateRefunds() && (
        <ListMenuItem route="/me/account/retainership-refund">
          <FaUndo size={26} style={{ marginRight: 10 }} />
          Process Retainership Refund
        </ListMenuItem>
      )}

      {billingPermissions.canViewReconciliation() && (
        <ListMenuItem route="/me/account/balance-reconciliation">
          <FaBalanceScale size={26} style={{ marginRight: 10 }} />
          Balance Reconciliation
        </ListMenuItem>
      )}

      <ListMenuItem route="/me/account/hmo-billing-report">
        <BsFillBarChartFill size={26} style={{ marginRight: 10 }} />
        HMO Billing Report
      </ListMenuItem>

      {billingPermissions.canViewAccounts() && (
        <ListMenuItem route="/me/account/client-statement">
          <GoNote size={26} style={{ marginRight: 10 }} />
          Account Statement
        </ListMenuItem>
      )}

      {billingPermissions.canViewBills() && (
        <ListMenuItem route="/me/account/patient-bill">
          <BsFillAwardFill size={26} style={{ marginRight: 10 }} />
          Pending Patient Bill
        </ListMenuItem>
      )}

      {billingPermissions.canCreatePayments() && (
        <ListMenuItem route="/me/account/review/opd-service?tab=OPD%20Services">
          <FaAddressCard size={26} style={{ marginRight: 10 }} />
          Cashier Page
        </ListMenuItem>
      )}

      {billingPermissions.canEditServices() && (
        <ListMenuItem route="/me/account/setup-services">
          <AiOutlineEdit size={26} style={{ marginRight: 10 }} />
          Click to Create/Edit Services
        </ListMenuItem>
      )}

      {billingPermissions.canEditAccountChart() && (
        <ListMenuItem route="/me/account/chart">
          <AiOutlineBranches size={26} style={{ marginRight: 10 }} />
          Setup Account Chart
        </ListMenuItem>
      )}

      {billingPermissions.canViewManagedCare() && (
        <ListMenuItem route="/me/account/managed-care">
          <FaHospital size={26} style={{ marginRight: 10 }} />
          Managed Care Settings
        </ListMenuItem>
      )}
    </VerticalMenu>
  );
};

export default AccountMenu;
```

---

## Benefits of Migration

1. **Cleaner Code** - No more nested ternaries
2. **Better Readability** - Clear permission names
3. **Type Safety** - Helper functions provide autocomplete
4. **Centralized Logic** - All permission checks in one place
5. **Easier Testing** - Mock permission helpers easily
6. **Granular Control** - Fine-grained permission checks
7. **Role-Based** - Permissions tied to roles in database

---

## Testing

After migration, test with different user roles:

1. **Admin** - Should see all menu items
2. **Accountant** - Should see all billing items
3. **Cashier** - Should see payment-related items only
4. **Billing Manager** - Should see most items except setup

---

## Rollback Plan

If issues arise, the legacy system still works:
- Keep old imports
- Revert to `canUseThis()` checks
- Both systems can coexist during transition
