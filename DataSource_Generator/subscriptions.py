from pathlib import Path
import random
from datetime import timedelta
import numpy as np
import pandas as pd
from faker import Faker
fake = Faker()

OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

random.seed(42)
np.random.seed(42)
users = pd.read_csv(OUTPUT_DIR/"users.csv")
users = users.sample(frac=0.85, random_state=42).reset_index(drop=True)

# segmentation
plans = ["Basic", "Standard", "Premium"]
plan_weights = [0.35, 0.45, 0.20]
monthly_prices = {
    "Basic": 9.99,
    "Standard": 15.49,
    "Premium": 22.99
}

annual_prices = {
    "Basic": 99.99,
    "Standard": 154.99,
    "Premium": 229.99
}

COUNTRY_PRICING = {
    "United States": {
        "currency": "USD",
        "Basic": 9.99,
        "Standard": 15.49,
        "Premium": 22.99
    },

    "India": {
        "currency": "INR",
        "Basic": 199,
        "Standard": 499,
        "Premium": 649
    },

    "United Kingdom": {
        "currency": "GBP",
        "Basic": 6.99,
        "Standard": 10.99,
        "Premium": 15.99
    },

    "Canada": {
        "currency": "CAD",
        "Basic": 9.99,
        "Standard": 16.49,
        "Premium": 20.99
    },

    "Germany": {
        "currency": "EUR",
        "Basic": 7.99,
        "Standard": 12.99,
        "Premium": 17.99
    },

    "Brazil": {
        "currency": "BRL",
        "Basic": 21.90,
        "Standard": 39.90,
        "Premium": 55.90
    },

    "Japan": {
        "currency": "JPY",
        "Basic": 990,
        "Standard": 1490,
        "Premium": 1980
    }
}


statuses = ["ACTIVE", "CANCELLED", "EXPIRED"]
status_weights = [0.80, 0.15, 0.05]


# Helper functions
def get_prices(plan, cycle):
    if cycle == 'Monthly':
        return monthly_prices[plan]
    return annual_prices[plan]
def generate_end_date(row):

    if row["subscription_status"] == "ACTIVE":
        return pd.NaT

    return fake.date_between(
        start_date=row["start_date"].date(),
        end_date="today"
    )
def auto_renew(status):
    if status == "ACTIVE":
        return random.random() < 0.90
    return False

def get_subscription_details(country, plan, billing_cycle):

    details = COUNTRY_PRICING[country]

    currency = details["currency"]

    monthly_price = details[plan]

    if billing_cycle == "Annual":
        price = round(monthly_price * 12 * 0.90, 2)
    else:
        price = monthly_price

    return pd.Series([currency, price])


# generate data
users["subscription_id"] = [f"SUB{i:08d}" for i in range(1, len(users) + 1)]
users["plan_name"] = random.choices(plans, weights=plan_weights, k=len(users))
billing = ["Monthly", "Annual"]
users['billing_cycle'] = random.choices(billing, weights=[0.80,0.20], k = len(users))

users[["currency", "subscription_price"]] = users.apply(
    lambda row: get_subscription_details(
        row["country"],
        row["plan_name"],
        row["billing_cycle"]
    ),
    axis=1
)

users["subscription_status"] = random.choices(statuses, weights=status_weights, k=len(users))
users["start_date"] = pd.to_datetime(users["signup_date"])
users["end_date"] = users.apply( generate_end_date, axis=1)
users["end_date"] = pd.to_datetime(users["end_date"])
users["auto_renew"] = users["subscription_status"].apply(auto_renew)
subscriptions = users[
    [
        "subscription_id",
        "user_id",
        "plan_name",
        "subscription_price",
        "currency",
        "billing_cycle",
        "start_date",
        "end_date",
        "auto_renew",
        "subscription_status"
    ]
]
subscriptions.to_parquet(OUTPUT_DIR/"subscriptions.parquet",
    index=False)