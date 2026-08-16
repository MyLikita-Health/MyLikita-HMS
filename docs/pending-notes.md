


http://localhost:46990/dental/appointments/create
{
    "patient_id": "5-1",
    "dentist_id": "868",
    "appointment_type": "consultation",
    "appointment_date": "2026-03-12T16:19",
    "duration_minutes": 30,
    "chief_complaint": "some complaint",
    "notes": "",
    "source": "admin",
    "facilityId": "1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a",
    "created_by": 879,
    "payment_status": "pending"
}


"/me/account/bill-preview" this bill preview page, i want the bill preview to show a 
preview on a real receipt with the hospital's letter head and nicely formatted, but the 
title in this case would be "Bill", the preview size should be in thermal receipt printer paper size,
which will print when print button is clicked, when download is clicked, it shuold generate
the pdf of the exact previewed bill in thermal receipt printer paper size



Cash Flow Error: TypeError: activities.forEach is not a function
    at exports.getCashFlow (/Users/mac/Documents/projects/mylikita/dental/backend/controller/financial-reports.js:335:16)
GET /financial-reports/cash-flow/2026-02-28/2026-03-10/1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a 500 18.516 ms - 115