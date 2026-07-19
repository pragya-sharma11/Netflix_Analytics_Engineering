from pathlib import Path
import pandas as pd


currency_to_usd = {
    "USD": 1.00,
    "EUR": 1.17,
    "GBP": 1.35,
    "INR": 0.012,
    "JPY": 0.0068,
    "CAD": 0.73,
    "AUD": 0.66,
    "BRL": 0.18,
    "MXN": 0.053,
    "KRW": 0.00072,
    "CNY": 0.14,
    "SGD": 0.78,
    "CHF": 1.24,
    "AED": 0.27,
    "SAR": 0.27,
    "ZAR": 0.056,
    "SEK": 0.11,
    "NOK": 0.096,
    "NZD": 0.60,
    "TRY": 0.025
}
currency_to_country = {
    "USD": "United States",
    "EUR": "Germany",          # Representative Eurozone country
    "GBP": "United Kingdom",
    "INR": "India",
    "JPY": "Japan",
    "CAD": "Canada",
    "AUD": "Australia",
    "BRL": "Brazil",
    "MXN": "Mexico",
    "KRW": "South Korea",
    "CNY": "China",
    "SGD": "Singapore",
    "CHF": "Switzerland",
    "AED": "United Arab Emirates",
    "SAR": "Saudi Arabia",
    "ZAR": "South Africa",
    "SEK": "Sweden",
    "NOK": "Norway",
    "NZD": "New Zealand",
    "TRY": "Turkey"
}
df = pd.DataFrame({'exchange_rates': list(currency_to_usd.values()), 'currency': list(currency_to_usd.keys())})
df['country'] = df['currency'].map(currency_to_country)
df.to_parquet('../Datasources/us_exchange_rates.parquet')