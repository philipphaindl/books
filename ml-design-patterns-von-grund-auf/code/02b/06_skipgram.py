"""Skip-Gram im Kleinen: Wortvektoren aus dem Vorhersagen von Nachbarwörtern (Vollständiges Softmax)."""
import numpy as np

from mlp import softmax, speichere

GRUPPEN = {  # Themen eines Helpdesks: Gegenstände (Subjekte) und typische Meldungen
    "hardware": (["drucker", "scanner", "monitor", "tastatur"], ["papierstau", "toner", "kabelbruch", "defekt"]),
    "zugang": (["passwort", "login", "konto", "token"], ["gesperrt", "abgelaufen", "zurückgesetzt", "ungültig"]),
    "netz": (["vpn", "wlan", "router", "proxy"], ["getrennt", "langsam", "timeout", "instabil"]),
}
rng = np.random.default_rng(0)
saetze = []
for _ in range(600):
    subjekte, meldungen = GRUPPEN[rng.choice(list(GRUPPEN))]
    k1, k2 = rng.choice(meldungen, 2, replace=False)
    saetze.append(["der", rng.choice(subjekte), "ist", k1, "und", k2])

woerter = sorted({w for s in saetze for w in s})
nr = {w: i for i, w in enumerate(woerter)}
V, D, FENSTER = len(woerter), 8, 2

# Trainingspaare (Mittelwort, Kontextwort) aus dem Fenster, je Satz einzeln
paare = np.array([(nr[s[i]], nr[s[j]]) for s in saetze for i in range(len(s))
                  for j in range(max(0, i - FENSTER), min(len(s), i + FENSTER + 1)) if j != i])
print(f"{len(saetze)} Sätze, Vokabular {V} Wörter, {len(paare)} Trainingspaare, Vektorlänge {D}")
print("'drucker' und 'scanner' gemeinsam in einem Satz:", sum({"drucker", "scanner"} <= set(s) for s in saetze), "mal")

W_ein = rng.normal(0, 0.1, (V, D))  # die Wortvektoren: eine Zeile je Wort
W_aus = rng.normal(0, 0.1, (D, V))  # Gewichte der Ausgabeschicht
lr, batch = 0.5, 128
for epoche in range(30):
    rng.shuffle(paare)
    gesamt = 0.0
    for s in range(0, len(paare), batch):
        c, o = paare[s:s + batch, 0], paare[s:s + batch, 1]
        h = W_ein[c]  # Lookup wie bei einer Embedding-Schicht
        p = softmax(h @ W_aus)  # P(Wort ist Nachbar)
        gesamt += -np.log(p[np.arange(len(o)), o]).sum()
        dz = p.copy()
        dz[np.arange(len(o)), o] -= 1
        dz /= len(o)
        np.add.at(W_ein, c, -lr * (dz @ W_aus.T))  # add.at summiert Doppelte
        W_aus -= lr * (h.T @ dz)
    if epoche in (0, 4, 29):
        print(f"Epoche {epoche + 1:2d}: Loss je Paar {gesamt / len(paare):.3f}  (Raten: ln {V} = {np.log(V):.3f})")


def kosinus(a, b):
    va, vb = W_ein[nr[a]], W_ein[nr[b]]
    return va @ vb / (np.linalg.norm(va) * np.linalg.norm(vb))


print()
for a, b in [("drucker", "scanner"), ("passwort", "login"), ("vpn", "router"), ("drucker", "passwort"), ("drucker", "vpn"), ("toner", "papierstau"), ("toner", "gesperrt")]:
    print(f"Kosinus({a}, {b}) = {kosinus(a, b):+.2f}")
nachbarn = sorted((w for w in woerter if w != "drucker"), key=lambda w: -kosinus("drucker", w))[:3]
print("Nächste Wörter zu 'drucker':", ", ".join(f"{w} ({kosinus('drucker', w):+.2f})" for w in nachbarn))

# Zweidimensionale Ansicht per Hauptkomponentenanalyse (PCA)
Z = W_ein - W_ein.mean(axis=0)
U, S, Vt = np.linalg.svd(Z, full_matrices=False)
xy = Z @ Vt[:2].T
print(f"\nPCA: die ersten zwei Richtungen erklären {100 * (S[:2] ** 2).sum() / (S ** 2).sum():.0f} % der Streuung")
gruppe = {w: g for g, (sub, mel) in GRUPPEN.items() for w in sub + mel}
speichere("skipgram", [{"wort": w, "x": round(float(xy[nr[w]][0]), 3), "y": round(float(xy[nr[w]][1]), 3),
                        "gruppe": gruppe.get(w, "funktion"), "subjekt": w in sum((s for s, _ in GRUPPEN.values()), [])} for w in woerter])
