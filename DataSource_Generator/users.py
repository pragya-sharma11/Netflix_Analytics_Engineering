from pathlib import Path
import numpy as np
import pandas as pd
from faker import Faker
from tqdm import tqdm
import random
from datetime import datetime
# Number of users to generate
NUM_USERS = 1_000_000
# Random Seed
RANDOM_SEED = 42
# Output Directory
OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)
fake = Faker()

# ---------------------------------------------
# Master Data
# ---------------------------------------------

COUNTRIES = {
    "United States": 0.35,
    "India": 0.25,
    "United Kingdom": 0.10,
    "Canada": 0.10,
    "Germany": 0.08,
    "Brazil": 0.07,
    "Japan": 0.05
}

LANGUAGES = {
    "United States": ["English"],
    "India": ["English", "Hindi"],
    "United Kingdom": ["English"],
    "Canada": ["English", "French"],
    "Germany": ["German"],
    "Brazil": ["Portuguese"],
    "Japan": ["Japanese"]
}

ACCOUNT_STATUS = {
    "ACTIVE": 0.94,
    "SUSPENDED": 0.03,
    "DELETED": 0.02,
    "PENDING_VERIFICATION": 0.01
}

GENDERS = ["Male", "Female"]

country_list = list(COUNTRIES.keys())
country_weights = list(COUNTRIES.values())
status_list = list(ACCOUNT_STATUS.keys())
status_weights = list(ACCOUNT_STATUS.values())

# Generator Functions
def generate_user_id(i):
    return f"USR{i:08d}"

def generate_country():
    return random.choices(country_list, weights=country_weights, k=1)[0]

def generate_language(country):
    return random.choice(LANGUAGES[country])

def generate_status():
    return random.choices(status_list, weights=status_weights, k=1)[0]

def generate_signup_date():
    return fake.date_time_between(
        start_date="-7y",
        end_date="now"
    )

def generate_dob():
    return fake.date_of_birth(
        minimum_age=18,
        maximum_age=75
    )

# create data rows
rows = []
for i in tqdm(range(1, NUM_USERS + 1)):
    country = generate_country()
    first_name = fake.first_name()
    last_name = fake.last_name()
    user = {
        "user_id": generate_user_id(i),
        "first_name": first_name,
        "last_name": last_name,
        "email": f"usr{i:08d}@netflix-demo.com",
        "phone_number": fake.phone_number(),
        "date_of_birth": generate_dob(),
        "gender": random.choice(GENDERS),
        "country": country,
        "state": fake.state(),
        "city": fake.city(),
        "preferred_language": generate_language(country),
        "signup_date": generate_signup_date(),
        "account_status": generate_status()
    }

    rows.append(user)

# create parquet file based on the above data
df = pd.DataFrame(rows)
df.to_csv(
   OUTPUT_DIR/ "users.csv",
    index=False
)

print(df.head())

print(df.shape)