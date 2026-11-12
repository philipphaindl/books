"""Rollout: Wie viele Beobachtungen braucht ein A/B-Test, was bringt der Shadow-Modus?

Altes Modell: lineare Regression ohne Abendspitze. Neues Modell: Boosting aus Pattern 16.
Zielgröße: Anteil der Lieferungen, bei denen die Vorhersage höchstens 3 Minuten abweicht.
Ausführen:  uv run --with scikit-learn --with pandas --with numpy --with scipy python rollout.py
"""
import numpy as np
from scipy.stats import norm, ttest_rel
from sklearn.linear_model import LinearRegression

from lieferdaten import MERKMALE, lieferdaten, modell_trainieren

train = lieferdaten(5000, seed=42)
live = lieferdaten(20_000, seed=7)  # eine Woche Verkehr, Labels nachträglich bekannt

alt_spalten = ["distanz_km", "artikel", "regen"]
alt = LinearRegression().fit(train[alt_spalten], train["lieferzeit_min"])
neu = modell_trainieren(train)

fehler_alt = (live["lieferzeit_min"] - alt.predict(live[alt_spalten])).abs()
fehler_neu = (live["lieferzeit_min"] - neu.predict(live[MERKMALE])).abs()
p_alt, p_neu = (fehler_alt <= 3).mean(), (fehler_neu <= 3).mean()
print(f"Trefferquote (Fehler <= 3 min): alt {p_alt:.3f}, neu {p_neu:.3f}")
print(f"MAE: alt {fehler_alt.mean():.2f} min, neu {fehler_neu.mean():.2f} min")

# Signifikanz 5 % (zweiseitig), Power 80 %
Z_ALPHA, Z_BETA = norm.ppf(1 - 0.05 / 2), norm.ppf(0.80)


def n_pro_gruppe(p1, p2):
    """Beobachtungen je Gruppe, um p1 von p2 zu unterscheiden (Näherung)."""
    mittel = (p1 + p2) / 2
    streuung = (Z_ALPHA * np.sqrt(2 * mittel * (1 - mittel))
                + Z_BETA * np.sqrt(p1 * (1 - p1) + p2 * (1 - p2)))
    return streuung ** 2 / (p1 - p2) ** 2


def zeile(text, n):
    return f"  {text:<46s}{np.ceil(n):>9,.0f}".replace(",", ".")


print("\nA/B-Test: nötige Beobachtungen je Gruppe")
for delta in (0.10, 0.05, 0.02, 0.01):
    print(zeile(f"{p_alt:.2f} -> {p_alt + delta:.2f} (+{delta * 100:.0f} Prozentpunkte)",
                n_pro_gruppe(p_alt, p_alt + delta)))
print(zeile(f"hier: +{(p_neu - p_alt) * 100:.1f} Prozentpunkte", n_pro_gruppe(p_alt, p_neu)))

# Shadow-Modus: beide Modelle sehen dieselben Anfragen, der Vergleich ist gepaart.
differenz = fehler_alt - fehler_neu
t, p = ttest_rel(fehler_alt, fehler_neu)
n_shadow = ((Z_ALPHA + Z_BETA) * differenz.std() / differenz.mean()) ** 2
anfragen = f"{len(live):,}".replace(",", ".")
print(f"\nShadow-Modus, gepaarter Vergleich der Fehler ({anfragen} Anfragen)")
print(f"  mittlere Verbesserung {differenz.mean():.2f} min, t = {t:.1f}")
print(zeile("nötige Anfragen (5 % / 80 % Power)", n_shadow))
