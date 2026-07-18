import random
import numpy as np
import pandas as pd
from datetime import timedelta
from pathlib import Path
random.seed(42)
np.random.seed(42)

# ----------------------------------------------------------
# Load Data
# ----------------------------------------------------------
print('load data ')
OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
users = pd.read_csv(OUTPUT_DIR/"users.csv")
content = pd.read_parquet(OUTPUT_DIR/"content_catalog.parquet")

# Remove content with invalid duration_minutes
content = content[
    content["duration_minutes"].notna() &
    (content["duration_minutes"] > 0)
].copy()

content = content.reset_index(drop=True)

# ----------------------------------------------------------
# Config
# ----------------------------------------------------------
print('Config setup')
RECOMMENDATION_TYPES = [
    "Personalized",
    "Trending",
    "Continue Watching",
    "Popular",
    "New Release"
]

RECOMMENDATION_WEIGHTS = [
    45,
    20,
    15,
    10,
    10
]

REASON_MAPPING = {
    "Personalized": "Based on your viewing history",
    "Trending": "Trending in your country",
    "Continue Watching": "Continue Watching",
    "Popular": "Popular on Netflix",
    "New Release": "Recently Added"
}

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

recommendations = []

recommendation_counter = 1

# ----------------------------------------------------------
# Generate Recommendations
# ----------------------------------------------------------
print('Generate Recommendations')
for _, user in users.iterrows():

    n_recommendations = random.randint(5, 15)

    recommended = content.sample(
        n=n_recommendations,
        replace=False
    )

    recommendation_time = (
        pd.to_datetime(user["signup_date"])
        + pd.to_timedelta(random.randint(0, 30), unit="D")
    )

    rank = 1

    for _, movie in recommended.iterrows():

        rec_type = random.choices(
            RECOMMENDATION_TYPES,
            weights=RECOMMENDATION_WEIGHTS,
            k=1
        )[0]

        device = random.choices(
            DEVICES,
            weights=DEVICE_WEIGHTS,
            k=1
        )[0]

        # -------------------------
        # Click
        # -------------------------

        clicked = random.random() < 0.30

        watch_started = False
        watch_seconds = 0
        completed = False
        rating = None

        # -------------------------
        # Watch
        # -------------------------

        if clicked:

            watch_started = random.random() < 0.85

            if watch_started:

                runtime_seconds = int(movie["duration_minutes"] * 60)

                bucket = random.choices(
                    [1,2,3,4],
                    weights=[20,30,30,20],
                    k=1
                )[0]

                if bucket == 1:
                    pct = random.uniform(0.05,0.20)

                elif bucket == 2:
                    pct = random.uniform(0.20,0.60)

                elif bucket == 3:
                    pct = random.uniform(0.60,0.95)

                else:
                    pct = random.uniform(0.95,1.00)

                watch_seconds = int(runtime_seconds * pct)

                completed = pct >= 0.95

                if completed:

                    rating = random.choices(
                        [5,4,3,2,1],
                        weights=[35,30,20,10,5],
                        k=1
                    )[0]

        recommendations.append({

            "recommendation_id":
                f"REC{recommendation_counter:09d}",

            "user_id":
                user["user_id"],

            "content_id":
                movie["content_id"],

            "recommendation_timestamp":
                recommendation_time,

            "recommendation_type":
                rec_type,

            "recommendation_rank":
                rank,

            "recommendation_reason":
                REASON_MAPPING[rec_type],

            "device":
                device,

            "clicked":
                clicked,

            "watch_started":
                watch_started,

            "watch_time_seconds":
                watch_seconds,

            "completed":
                completed,

            "rating":
                rating

        })

        recommendation_counter += 1
        rank += 1
# ----------------------------------------------------------
# Create DataFrame
# ----------------------------------------------------------
print('create dataframe')
recommendation_logs = pd.DataFrame(recommendations)

# ----------------------------------------------------------
# Save
# ----------------------------------------------------------
print('save')
recommendation_logs.to_parquet(
    OUTPUT_DIR/"recommendation_logs.parquet",
    index=False
)
