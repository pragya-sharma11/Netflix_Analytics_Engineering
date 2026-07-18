from pathlib import Path

import pandas as pd
import json
import ast
import pycountry
import random
from faker import Faker

fake = Faker()

# Random Seed
RANDOM_SEED = 42
# Output Directory
OUTPUT_DIR = Path("Datasources")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
d = [{'a':21,'b':324},{'a':21,'b':324},{'a':21,'b':324}]

# df = pd.DataFrame(d)
content_df = pd.read_csv(OUTPUT_DIR/'movies_metadata.csv')

# convert columns to their valid datatype
def safe_eval(x):
    if pd.isna(x) or isinstance(x, float):
        return []
    if isinstance(x, list):
        return x
    if isinstance(x, str):
        try:
            return ast.literal_eval(x)
        except (ValueError, SyntaxError):
            return []
    return []

# change language code to language
def language_name(code):
    try:
        return pycountry.languages.get(alpha_2=code).name
    except:
        return code
    
df = content_df[
    [
        "title",
        "genres",
        "original_language",
        "release_date",
        "runtime",
        "vote_average",
        "production_countries"
    ]
]

df['content_type'] = 'Movie'
df['production_countries'] = df['production_countries'].apply(safe_eval)
df = df[~df["production_countries"].apply(lambda x: isinstance(x, float))]
df['country'] = df['production_countries'].apply(lambda x: x[0]['name'] if len(x)>0  else '')
df['country_iso'] = df['production_countries'].apply(lambda x: x[0]['iso_3166_1'] if len(x)>0 else '')
df['genres'] = df['genres'].apply(safe_eval)
df['genre'] = df['genres'].apply(lambda x: x[0]['name'] if len(x) > 0 else '')
df.insert(0,'content_id', [f'CNT{i:07d}' for i in range(1, len(df)+1)])
df['language'] = df['original_language'].apply(language_name)
df['release_year'] = pd.to_datetime(df['release_date'],  errors='coerce').dt.year
df['release_year'] = pd.to_numeric(df['release_year'], errors='coerce')
ratings = ["G", "PG", "PG-13", "R", "TV-MA"]
weights = [0.05, 0.25, 0.40, 0.20, 0.10]
df["maturity_rating"] = random.choices(
    ratings,
    weights=weights,
    k=len(df)
)

df["date_added_to_platform"] = [
    fake.date_between("-8y", "today")
    for _ in range(len(df))
]
df["is_available"] = random.choices(
    [True, False],
    weights=[98, 2],
    k=len(df)
)
df["director"] = "Unknown"
df["cast"] = "Unknown"
df = df[
    [
        "content_id",
        "title",
        "content_type",
        "genre",
        "language",
        "release_year",
        "runtime",
        "maturity_rating",
        "vote_average",
        "country",
        "director",
        "cast",
        "date_added_to_platform",
        "is_available"
    ]
]
df = df.rename(
    columns={
        "runtime": "duration_minutes",
        "vote_average": "imdb_rating"
    }
)
df.to_parquet(
    OUTPUT_DIR/"content_catalog.parquet",
    index=False
)
