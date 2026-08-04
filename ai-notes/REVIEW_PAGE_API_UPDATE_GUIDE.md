# Review Account Report - API Client Update Guide

## Summary
The Review.jsx file needs to be updated to use the authenticated apiClient instead of fetch and old API helpers.

## Changes Required

### 1. Update Imports
Replace:
```javascript
import {
  _deleteApi,
  _fetchApi2,
  _postApi,
  _updateApi,
} from "../../redux/actions/api";
```

With:
```javascript
import { get, post, put, del } from "../../utils/apiClient";
```

### 2. Update API Calls

#### getPatientIncome (line ~97)
Replace `fetch()` with `get()`:
```javascript
// OLD
fetch(`${apiURL()}/account/get-pending-tnx?...`)
  .then((raw) => raw.json())
  .then((data) => { ... })

// NEW
get(`/account/get-pending-tnx?type=group&from=${range.from}&to=${range.to}&facilityId=${user.facilityId}`)
  .then((response) => {
    const data = response.data;
    // ... rest of logic
  })
```

#### handleReview (line ~210)
Replace `_updateApi` with `put()`:
```javascript
// OLD
_updateApi(
  `${apiURL()}/transactions/review`,
  { finalist, status: "cashier approved" },
  ...
)

// NEW
put('/transactions/review', { finalist, status: "cashier approved" })
  .then((response) => { ... })
  .catch((error) => { ... })
```

#### handleDelete (line ~231)
Replace `_deleteApi` with `del()`:
```javascript
// OLD
_deleteApi(
  `${apiURL()}/lab/transaction/delete/${reference_no}`,
  {},
  ...
)

// NEW
del(`/lab/transaction/delete/${reference_no}`)
  .then((response) => { ... })
  .catch((error) => { ... })
```

#### getTxById (line ~330)
Replace `_fetchApi2` with `get()`:
```javascript
// OLD
_fetchApi2(
  `${apiURL()}/account/get-tx-by-id?transaction_id=${transaction_id}`,
  (data) => { ... },
  (error) => { ... }
)

// NEW
get(`/account/get-tx-by-id?transaction_id=${transaction_id}`)
  .then((response) => {
    const data = response.data;
    // ... rest of logic
  })
  .catch((error) => { ... })
```

#### getDiscount (line ~369)
Replace `_fetchApi2` with `get()`:
```javascript
// OLD
_fetchApi2(
  `${apiURL()}/discounts/all?query_type=select&facilityId=${facilityId}`,
  (d) => { ... },
  (error) => { ... }
)

// NEW
get(`/discounts/all?query_type=select&facilityId=${facilityId}`)
  .then((response) => {
    const d = response.data;
    // ... rest of logic
  })
  .catch((error) => { ... })
```

#### getInsuranceType (line ~381)
Replace `_fetchApi2` with `get()`:
```javascript
// OLD
_fetchApi2(
  `${apiURL()}/account/get-insurance-type?accountId=${client_acc}`,
  (d) => { ... },
  (error) => { ... }
)

// NEW
get(`/account/get-insurance-type?accountId=${client_acc}`)
  .then((response) => {
    const d = response.data;
    // ... rest of logic
  })
  .catch((error) => { ... })
```

#### handleApprove (line ~408)
Replace nested `_fetchApi2` and `_postApi` with `get()` and `post()`:
```javascript
// OLD
_fetchApi2(
  `${apiURL()}/lab/lab-summary?...`,
  (data) => {
    for (let i = 0; i < data.results.length; i++) {
      _postApi(
        `${apiURL()}/txn/cashier-approval`,
        { ... },
        ...
      )
    }
  }
)

// NEW
get(`/lab/lab-summary?type=pending approval detail&report_by=${item.client_id}`)
  .then((response) => {
    const data = response.data;
    const promises = data.results.map((curr) => 
      post('/txn/cashier-approval', { ... })
    );
    return Promise.all(promises);
  })
  .then(() => { ... })
  .catch((error) => { ... })
```

#### handlePayment (line ~516)
Replace `_postApi` with `post()`:
```javascript
// OLD
_postApi(
  `${apiURL()}/account/casher-pay-bill`,
  { ... },
  (data) => { ... },
  (error) => { ... }
)

// NEW
post('/account/casher-pay-bill', { ... })
  .then((response) => {
    const data = response.data;
    // ... rest of logic
  })
  .catch((error) => { ... })
```

#### addToBill (line ~595)
Replace `_postApi` with `post()`:
```javascript
// OLD
_postApi(
  `${apiURL()}/account/casher-pay-bill`,
  { ... },
  (data) => { ... },
  (error) => { ... }
)

// NEW
post('/account/casher-pay-bill', { ... })
  .then((response) => {
    const data = response.data;
    // ... rest of logic
  })
  .catch((error) => { ... })
```

## Benefits
1. Automatic authentication token inclusion
2. Automatic token refresh on expiry
3. Consistent error handling
4. Better security
5. Cleaner code with async/await pattern

## Testing
After updates, test:
1. Loading pending transactions
2. Reviewing/approving transactions
3. Deleting transactions
4. Payment processing
5. Discount application
6. Insurance type fetching
