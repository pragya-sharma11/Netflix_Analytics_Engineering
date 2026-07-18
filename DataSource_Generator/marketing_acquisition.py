import random
from pathlib import Path
import numpy as np
import pandas as pd

random.seed(42)
np.random.seed(42)

# -------------------------------------------------------
# Load Users
# -------------------------------------------------------
OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
users = pd.read_csv(OUTPUT_DIR/"users.csv")

# -------------------------------------------------------
# Acquisition Channels
# -------------------------------------------------------

CHANNELS = [
    "Organic Search",
    "Google Ads",
    "Facebook Ads",
    "Instagram Ads",
    "Referral",
    "Email",
    "Affiliate",
    "Apple App Store",
    "Google Play Store"
]

CHANNEL_WEIGHTS = [
    30,
    20,
    15,
    10,
    10,
    5,
    5,
    3,
    2
]

# -------------------------------------------------------
# Campaign Type Mapping
# -------------------------------------------------------

CAMPAIGN_TYPE = {
    "Organic Search": "Organic",
    "Google Ads": "Paid Search",
    "Facebook Ads": "Paid Social",
    "Instagram Ads": "Paid Social",
    "Referral": "Referral",
    "Email": "CRM",
    "Affiliate": "Affiliate",
    "Apple App Store": "App Store",
    "Google Play Store": "App Store"
}

# -------------------------------------------------------
# Cost Per Acquisition (USD)
# -------------------------------------------------------

CHANNEL_COST = {
    "Organic Search": 0,
    "Google Ads": 18,
    "Facebook Ads": 15,
    "Instagram Ads": 12,
    "Referral": 5,
    "Email": 2,
    "Affiliate": 10,
    "Apple App Store": 8,
    "Google Play Store": 8
}

# -------------------------------------------------------
# Device Distribution
# -------------------------------------------------------

DEVICES = [
    "Mobile",
    "Smart TV",
    "Web",
    "Tablet"
]

DEVICE_WEIGHTS = [
    50,
    20,
    20,
    10
]

# -------------------------------------------------------
# Generate Marketing Acquisition
# -------------------------------------------------------

marketing = []

for i, row in users.iterrows():

    channel = random.choices(
        CHANNELS,
        weights=CHANNEL_WEIGHTS,
        k=1
    )[0]

    marketing.append({

        "acquisition_id": f"ACQ{i+1:09d}",

        "user_id": row["user_id"],

        "acquisition_date": row["signup_date"],

        "acquisition_channel": channel,

        "campaign_type": CAMPAIGN_TYPE[channel],

        "campaign_cost": CHANNEL_COST[channel],

        "device": random.choices(
            DEVICES,
            weights=DEVICE_WEIGHTS,
            k=1
        )[0],

        "country": row["country"]

    })

# -------------------------------------------------------
# Create DataFrame
# -------------------------------------------------------

marketing = pd.DataFrame(marketing)

# -------------------------------------------------------
# Save
# -------------------------------------------------------

marketing.to_parquet(
    OUTPUT_DIR/"marketing_acquisition.parquet",
    index=False
)

