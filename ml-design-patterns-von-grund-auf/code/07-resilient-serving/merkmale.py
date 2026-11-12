"""Feature Engineering, das zum Modell gehört. Muss beim Laden des Modells importierbar sein."""
import pandas as pd


def abendspitze_ergaenzen(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["abendspitze"] = df["stunde"].between(18, 20).astype(int)
    return df
