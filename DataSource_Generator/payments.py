from pathlib import Path
import random
import numpy as np
import pandas as pd

random.seed(42)
np.random.seed(42)
OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------
# Load Subscriptions
# -------------------------------------------------------
print('Load Subscriptions')
subscriptions = pd.read_parquet(OUTPUT_DIR/"subscriptions.parquet")

today = pd.Timestamp.today().normalize()

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
print('Configuration')
PAYMENT_METHODS = [
    "Credit Card",
    "Debit Card",
    "PayPal",
    "UPI",
    "Gift Card"
]

PAYMENT_METHOD_WEIGHTS = [
    0.45,
    0.25,
    0.10,
    0.15,
    0.05
]

FAILURE_REASONS = [
    "Insufficient Funds",
    "Card Expired",
    "Bank Declined",
    "Network Error",
    "Fraud Check Failed"
]

FAILURE_REASON_WEIGHTS = [
    0.35,
    0.20,
    0.20,
    0.15,
    0.10
]

payments = []
payment_counter = 1

# -------------------------------------------------------
# Generate Payments
# -------------------------------------------------------
print('Generate Payments')
for _, row in subscriptions.iterrows():

    start_date = pd.to_datetime(row["start_date"])

    end_date = (
        today
        if pd.isna(row["end_date"])
        else pd.to_datetime(row["end_date"])
    )

    freq = "MS" if row["billing_cycle"] == "Monthly" else "YS"

    billing_dates = pd.date_range(
        start=start_date,
        end=end_date,
        freq=freq
    )

    payment_method = random.choices(
        PAYMENT_METHODS,
        weights=PAYMENT_METHOD_WEIGHTS,
        k=1
    )[0]

    renewal_number = 1

    for due_date in billing_dates:

        # ---------------------------------------------------
        # Decide number of failed attempts before success
        #
        # 80% -> No failure
        # 15% -> One failure
        # 5%  -> Two failures
        #
        # Overall payment record ratio ≈ 80:20
        # ---------------------------------------------------

        num_failures = random.choices(
            population=[0, 1, 2],
            weights=[80, 15, 5],
            k=1
        )[0]

        # -----------------------------
        # Failed Payment Attempts
        # -----------------------------

        for attempt in range(num_failures):

            payments.append({

                "payment_id": f"PAY{payment_counter:09d}",

                "subscription_id": row["subscription_id"],

                "user_id": row["user_id"],

                "original_due_date": due_date,

                "payment_date": due_date + pd.Timedelta(days=attempt),

                "amount": row["subscription_price"],

                "currency": row["currency"],

                "payment_method": payment_method,

                "payment_status": "FAILED",

                "payment_failure_reason": random.choices(
                    FAILURE_REASONS,
                    weights=FAILURE_REASON_WEIGHTS,
                    k=1
                )[0],

                "refund_amount": 0,

                "renewal_number": renewal_number

            })

            payment_counter += 1

        # -----------------------------
        # Successful Payment
        # -----------------------------

        refunded = random.random() < 0.02

        payments.append({

            "payment_id": f"PAY{payment_counter:09d}",

            "subscription_id": row["subscription_id"],

            "user_id": row["user_id"],

            "original_due_date": due_date,

            "payment_date": due_date + pd.Timedelta(days=num_failures),

            "amount": row["subscription_price"],

            "currency": row["currency"],

            "payment_method": payment_method,

            "payment_status": "REFUNDED" if refunded else "SUCCESS",

            "payment_failure_reason": None,

            "refund_amount": (
                row["subscription_price"]
                if refunded
                else 0
            ),

            "renewal_number": renewal_number

        })

        payment_counter += 1
        renewal_number += 1

# -------------------------------------------------------
# Create DataFrame
# -------------------------------------------------------
print('Create Dataframe')
payments = pd.DataFrame(payments)

payments = payments.sort_values(
    ["user_id", "payment_date"]
).reset_index(drop=True)

# -------------------------------------------------------
# Save
# -------------------------------------------------------
print('Save File')
payments.to_parquet(
    OUTPUT_DIR/"payments.parquet",
    index=False
)
print(payments.shape)

# -------------------------------------------------------
# Sanity Checks
# -------------------------------------------------------

print("\nPayment Status Distribution")
print(
    payments["payment_status"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)

print("\nFailure Reasons")
print(payments["payment_failure_reason"].value_counts())