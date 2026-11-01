"""
EcoVision AI – Core pipeline
Handles: text analysis, image analysis, semantic search, chat
"""
from __future__ import annotations

import logging
import os
import re
from pathlib import Path
from typing import List, Tuple

import numpy as np

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────
# Lazy singletons
# ──────────────────────────────────────────────
_embedder = None
_faiss_index = None
_doc_store: List[dict] = []

ECO_KEYWORDS = {
    "deforestation": ["deforestation", "forest", "logging", "tree", "amazon", "rainforest", "clear-cutting"],
    "pollution": ["pollution", "toxic", "chemical", "waste", "contamination", "smog", "emission"],
    "wildlife": ["wildlife", "endangered", "species", "biodiversity", "extinction", "habitat", "fauna"],
    "ocean": ["ocean", "marine", "coral", "reef", "plastic", "sea", "fishing", "overfishing"],
    "climate": ["climate", "carbon", "greenhouse", "co2", "warming", "temperature", "ice", "arctic"],
    "energy": ["energy", "renewable", "solar", "wind", "fossil", "coal", "oil", "gas", "nuclear"],
    "waste": ["waste", "recycling", "landfill", "composting", "plastic", "single-use", "packaging"],
}

RECOMMENDATIONS_MAP = {
    "deforestation": [
        "Support certified sustainable forestry (FSC-certified products).",
        "Advocate for REDD+ programs in your region.",
        "Plant native trees through local reforestation initiatives.",
    ],
    "pollution": [
        "Switch to electric vehicles or public transport.",
        "Reduce single-use plastics in daily routine.",
        "Support stricter industrial emission regulations.",
    ],
    "wildlife": [
        "Donate to habitat preservation organisations.",
        "Avoid products linked to illegal wildlife trade.",
        "Create wildlife-friendly spaces in your garden.",
    ],
    "ocean": [
        "Participate in beach clean-up events.",
        "Choose sustainably sourced seafood (MSC-certified).",
        "Reduce plastic packaging use to cut ocean plastic.",
    ],
    "climate": [
        "Calculate and offset your carbon footprint.",
        "Shift to a plant-rich diet.",
        "Install solar panels or join a community energy scheme.",
    ],
    "energy": [
        "Audit home energy use and improve insulation.",
        "Switch to a renewable energy tariff.",
        "Replace appliances with energy-efficient models.",
    ],
    "waste": [
        "Follow the 5 Rs: Refuse, Reduce, Reuse, Repurpose, Recycle.",
        "Compost organic waste at home.",
        "Buy second-hand or refurbished products.",
    ],
    "general": [
        "Educate yourself and others on environmental issues.",
        "Support environmental NGOs and policy change.",
        "Measure, reduce, and offset your carbon footprint.",
    ],
}


def get_embedder():
    global _embedder
    if _embedder is None:
        try:
            from sentence_transformers import SentenceTransformer
            _embedder = SentenceTransformer("all-MiniLM-L6-v2")
            logger.info("Embedding model loaded.")
        except Exception as e:
            logger.warning(f"Could not load SentenceTransformer: {e}")
            _embedder = None
    return _embedder


# ──────────────────────────────────────────────
# Text analysis
# ──────────────────────────────────────────────
def detect_category(text: str) -> str:
    text_lower = text.lower()
    scores: dict[str, int] = {cat: 0 for cat in ECO_KEYWORDS}
    for cat, kws in ECO_KEYWORDS.items():
        for kw in kws:
            scores[cat] += len(re.findall(r"\b" + re.escape(kw) + r"\b", text_lower))
    best = max(scores, key=lambda c: scores[c])
    return best if scores[best] > 0 else "general"


def compute_eco_score(text: str, category: str) -> float:
    """Simple keyword-density risk score (0–100, higher = more severe impact)."""
    text_lower = text.lower()
    keywords = ECO_KEYWORDS.get(category, [])
    if not keywords:
        return 20.0
    hits = sum(len(re.findall(r"\b" + re.escape(kw) + r"\b", text_lower)) for kw in keywords)
    word_count = max(len(text_lower.split()), 1)
    density = hits / word_count
    score = min(density * 1000, 100.0)
    return round(score, 2)


def analyse_text(text: str, category: str = "general") -> dict:
    detected_cat = detect_category(text) if category == "general" else category
    eco_score = compute_eco_score(text, detected_cat)
    confidence = min(0.5 + eco_score / 200, 0.99)

    severity = "low" if eco_score < 30 else "moderate" if eco_score < 60 else "high"
    summary = (
        f"The submitted text shows **{severity}** environmental concern "
        f"related to *{detected_cat}* (score: {eco_score}/100). "
        "Key impact indicators were detected based on semantic keyword analysis."
    )

    return {
        "category": detected_cat,
        "eco_score": eco_score,
        "summary": summary,
        "recommendations": RECOMMENDATIONS_MAP.get(detected_cat, RECOMMENDATIONS_MAP["general"]),
        "confidence": round(confidence, 2),
    }


# ──────────────────────────────────────────────
# Semantic search
# ──────────────────────────────────────────────
def add_to_index(texts: List[str], source: str = "upload") -> int:
    global _faiss_index, _doc_store
    embedder = get_embedder()
    if embedder is None:
        return 0
    import faiss
    vectors = embedder.encode(texts, convert_to_numpy=True).astype("float32")
    dim = vectors.shape[1]
    if _faiss_index is None:
        _faiss_index = faiss.IndexFlatL2(dim)
    _faiss_index.add(vectors)
    for t in texts:
        _doc_store.append({"text": t, "source": source})
    return len(texts)


def semantic_search(query: str, top_k: int = 5) -> List[dict]:
    global _faiss_index, _doc_store
    embedder = get_embedder()
    if embedder is None or _faiss_index is None or len(_doc_store) == 0:
        return _fallback_search(query, top_k)
    import faiss
    vec = embedder.encode([query], convert_to_numpy=True).astype("float32")
    D, I = _faiss_index.search(vec, min(top_k, len(_doc_store)))
    results = []
    for dist, idx in zip(D[0], I[0]):
        if idx < len(_doc_store):
            doc = _doc_store[idx]
            results.append({
                "text": doc["text"],
                "score": float(round(1 / (1 + dist), 4)),
                "source": doc["source"],
            })
    return results


def _fallback_search(query: str, top_k: int) -> List[dict]:
    """Return keyword-matched demo results when no index is built yet."""
    demos = [
        "Deforestation in the Amazon has accelerated due to agricultural expansion.",
        "Plastic pollution in oceans threatens marine biodiversity significantly.",
        "Renewable energy adoption can reduce carbon emissions by up to 70%.",
        "Wildlife corridors help preserve habitats and prevent species extinction.",
        "Urban green roofs lower city temperatures and improve air quality.",
    ]
    query_lower = query.lower()
    scored = [(d, sum(1 for w in query_lower.split() if w in d.lower())) for d in demos]
    scored.sort(key=lambda x: x[1], reverse=True)
    return [{"text": t, "score": round(s / max(1, len(query.split())), 3), "source": "demo"} for t, s in scored[:top_k]]


# ──────────────────────────────────────────────
# Chat
# ──────────────────────────────────────────────
ECO_CHAT_KNOWLEDGE = {
    "carbon": "Carbon dioxide (CO₂) is the primary greenhouse gas. The global average is now above 420 ppm, the highest in 3 million years.",
    "solar": "Solar energy is the fastest-growing renewable source. Costs have fallen 89% in the last decade.",
    "deforestation": "Tropical deforestation accounts for ~10% of global carbon emissions each year.",
    "plastic": "Over 8 million tonnes of plastic enter the oceans annually, affecting over 700 marine species.",
    "renewable": "Renewables (solar, wind, hydro) generated a record 30% of global electricity in 2023.",
    "biodiversity": "Earth has lost 69% of its wildlife population since 1970 according to WWF's Living Planet Index.",
    "recycling": "Recycling one tonne of paper saves 17 trees, 7,000 gallons of water, and 3 cubic yards of landfill space.",
    "electric": "Electric vehicles emit 50–70% less CO₂ over their lifetime compared to petrol/diesel cars.",
    "climate": "The Paris Agreement aims to limit global warming to 1.5 °C above pre-industrial levels.",
    "water": "Only 3% of Earth's water is fresh water; 68% of that is locked in glaciers and ice caps.",
}


def chat_response(messages: List[dict]) -> Tuple[str, List[str]]:
    last_user = next((m["content"] for m in reversed(messages) if m["role"] == "user"), "")
    lower = last_user.lower()

    hits = [key for key in ECO_CHAT_KNOWLEDGE if key in lower]
    if hits:
        facts = [ECO_CHAT_KNOWLEDGE[h] for h in hits[:2]]
        reply = " ".join(facts) + " Would you like more details or recommendations on this topic?"
        sources = [f"EcoVision Knowledge Base – {h.title()}" for h in hits[:2]]
    else:
        analysis = analyse_text(last_user)
        reply = (
            f"Based on your message, I detect concerns around **{analysis['category']}**. "
            f"{analysis['summary']} Here's what you can do:\n"
            + "\n".join(f"• {r}" for r in analysis["recommendations"])
        )
        sources = ["EcoVision AI Analysis Engine"]
    return reply, sources
