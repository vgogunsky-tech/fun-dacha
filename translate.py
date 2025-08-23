from deep_translator import GoogleTranslator
import pandas as pd
import time

# Load CSV
df = pd.read_csv("list.csv")

translator = GoogleTranslator(source='ru', target='uk')

# Iterate row by row
for idx, row in df.iterrows():
    if pd.isna(row['Описание (укр)']) and pd.notna(row['Описание (рус)']):
        try:
            translation = translator.translate(row['Описание (рус)'])
            df.at[idx, 'Описание (укр)'] = translation
            print(f"[{idx}] Translated successfully.")
        except Exception as e:
            print(f"[{idx}] Failed to translate: {e}")
        finally:
            # Save progress after each row
            df.to_csv("list_filled.csv", index=False)
            # Optional: avoid hitting rate limits
            time.sleep(0.5)
    else:
        print(f"[{idx}] Skipped (already translated or empty).")

print("Translation finished. Saved to list_filled.csv")

