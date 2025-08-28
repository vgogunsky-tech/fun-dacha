import pandas as pd
import logging
import re

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

# Paths
csv_path = "data/list.csv"

# Load CSV
logging.info(f"Loading CSV file: {csv_path}")
df = pd.read_csv(csv_path)
logging.info(f"Loaded CSV with shape {df.shape}")

def clean_description(text, title=""):
    """Clean description text according to all rules and capitalize first letter."""
    if not isinstance(text, str) or not text.strip():
        return text

    text = text.strip()

    # Remove title from start if present
    if isinstance(title, str) and text.lower().startswith(title.lower()):
        text = text[len(title):]

    # Remove leading periods, commas, spaces
    text = re.sub(r'^[\s.,]+', '', text)

    # Remove multiple consecutive dots or commas
    text = re.sub(r'\.{2,}', '.', text)
    text = re.sub(r',,{2,}', ',', text)

    # Remove any special character at the start
    text = re.sub(r'^[^A-Za-zА-Яа-я0-9]+', '', text)

    # Remove space before comma or period
    text = re.sub(r'\s+([,.])', r'\1', text)
    # Ensure single space after comma or period (if not end of text)
    text = re.sub(r'([,.])([^\s])', r'\1 \2', text)

    # Strip again to remove extra leading/trailing spaces
    text = text.strip()

    # Capitalize first letter
    if text:
        text = text[0].upper() + text[1:]

    return text

def capitalize_text(text):
    """Capitalize first letter and strip spaces."""
    if not isinstance(text, str) or not text.strip():
        return text
    text = text.strip()
    return text[0].upper() + text[1:]

# Columns to process
desc_columns_map = {
    "Описание (укр)": "Название (укр)",
    "Описание (рус)": "Название (рус)"
}

title_columns = ["Название (укр)", "Название (рус)"]

# Process title columns
for col in title_columns:
    if col not in df.columns:
        logging.warning(f"Column '{col}' not found in CSV!")
        continue

    logging.info(f"Processing title column: {col}")
    for i in range(len(df)):
        df.at[i, col] = capitalize_text(df.at[i, col])

# Process description columns
for desc_col, title_col in desc_columns_map.items():
    if desc_col not in df.columns:
        logging.warning(f"Column '{desc_col}' not found in CSV!")
        continue

    logging.info(f"Processing description column: {desc_col}")
    for i in range(len(df)):
        description = df.at[i, desc_col]
        title_text = df.at[i, title_col] if title_col in df.columns else ""
        df.at[i, desc_col] = clean_description(description, title_text)

# Save CSV
df.to_csv(csv_path, index=False)
logging.info("✅ Title and description normalization completed and saved to list.csv")
print("✅ Normalization complete. See list.csv")

