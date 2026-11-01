import re
from typing import List, Dict, Any, Optional
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/assistant", tags=["EcoAdvisor Assistant"])


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


class ChatResponse(BaseModel):
    reply: str
    sources: List[str]
    language_detected: str


MARATHI_KNOWLEDGE = {
    "कचरा": "कचऱ्याचे वर्गीकरण तीन भागात करणे आवश्यक आहे: ओला कचरा (हिरवा डबा), सुका कचरा (निळा डबा), आणि घातक/ई-कचरा (लाल डबा किंवा संकलन केंद्र).",
    "प्लास्टिक": "प्लास्टिकच्या बाटल्या व डबे स्वच्छ धुऊन कोरडे करा आणि निळ्या कचराकुंडीत टाका. पातळ प्लास्टिक पिशव्यांचा वापर टाळा.",
    "कागद": "स्वच्छ कागद, वह्या आणि पुठ्ठ्याचे खोके घडी करून सुक्या कचऱ्यात द्या. तेलकट किंवा खरकट कागद कम्पोस्टिंगसाठी किंवा सुक्या कचऱ्यात चालत नाही.",
    "काच": "काचेच्या बाटल्या आणि भांडी काळजीपूर्वक हाताळा. फुटलेली काच असल्यास वर्तमानपत्रात गुंडाळून त्यावर खूण करून द्या जेणेकरून सफाई मित्रांना दुखापत होणार नाही.",
    "सेंद्रिय": "सेंद्रिय आणि ओला कचरा (फळांची साले, भाज्या, खरकटे अन्न) हिरव्या डब्यात टाका किंवा सोसायटीच्या खत प्रकल्पात द्या. यामुळे उत्तम सेंद्रिय खत तयार होते.",
    "ई-कचरा": "जुने मोबाईल, बॅटरी, वायर आणि चार्जर महानगरपालिकेच्या ई-कचरा संकलन पेटीत किंवा अधिकृत रिसायकलिंग केंद्रातच जमा करा.",
}

HINDI_KNOWLEDGE = {
    "प्लास्टिक": "प्लास्टिक की बोतलों को खाली करके दबाएं और नीले सूखे कूड़ेदान में डालें। प्लास्टिक थैलियों का उपयोग कम से कम करें।",
    "कागज": "अखबार, किताबें और कार्डबोर्ड के डिब्बों को सूखा रखकर रीसाइक्लिंग के लिए नीले डिब्बे में दें।",
    "कांच": "कांच की बोतलें और जार धोकर रीसायकल करें। टूटे कांच को अखबार में सुरक्षित लपेटकर ही दें।",
    "गीला कचरा": "सब्जियों के छिलके और बचा हुआ भोजन हरे गीले कूड़ेदान में डालें। इसे होम कम्पोस्टिंग के लिए भी इस्तेमाल किया जा सकता है।",
    "सूखा कचरा": "कागज, प्लास्टिक, धातु के डिब्बे और कार्डबोर्ड को सूखे डिब्बे में अलग रखें।",
    "कचरा": "ठोस अपशिष्ट नियम के अनुसार कचरे को गीला, सूखा और खतरनाक श्रेणियों में अलग-अलग रखना अनिवार्य है।",
    "ई-कचरा": "इलेक्ट्रॉनिक सामान और बैटरियों को सामान्य कूड़े में न फेंके, इन्हें निर्धारित ई-कवेस्ट केंद्र पर पहुंचाएं।",
}


@router.post("/chat", response_model=ChatResponse)
def chat_with_advisor(request: ChatRequest) -> ChatResponse:
    if not request.messages:
        return ChatResponse(
            reply="Hello! I am EcoAdvisor. How can I assist you with waste sorting, recycling, or local eco-guidelines today?",
            sources=["EcoVision Assistant Core"],
            language_detected="en",
        )

    # Get the latest user message
    user_msgs = [m for m in request.messages if m.role.lower() == "user"]
    last_text = user_msgs[-1].content if user_msgs else request.messages[-1].content
    text_lower = last_text.lower()

    # Detect language: check Devanagari script
    has_devanagari = bool(re.search(r"[\u0900-\u097F]", last_text))

    detected_lang = "en"
    reply = ""
    sources = ["EcoVision Knowledge Base", "Solid Waste Management Guidelines (SWM Rules)"]

    if has_devanagari:
        # Check Marathi specific words first
        marathi_hits = [k for k in MARATHI_KNOWLEDGE if k in last_text]
        hindi_hits = [k for k in HINDI_KNOWLEDGE if k in last_text]

        if any(w in last_text for w in ["कचरा", "सेंद्रिय", "कागद", "नमस्कार", "हॅलो", "कसा", "आहे"]):
            detected_lang = "mr"
            sources.append("पुणे महानगरपालिका घनकचरा व्यवस्थापन नियम")

            matched_replies = [MARATHI_KNOWLEDGE[k] for k in marathi_hits]
            if matched_replies:
                reply = " ".join(matched_replies)
            else:
                reply = "नमस्कार! मी EcoAdvisor आहे. कचरा वर्गीकरण, प्लास्टिक, काच, कागद किंवा सेंद्रिय खताबद्दल तुम्हाला कोणती माहिती हवी आहे?"
        else:
            detected_lang = "hi"
            sources.append("केंद्रीय प्रदूषण नियंत्रण बोर्ड (CPCB) अपशिष्ट नियम")

            matched_replies = [HINDI_KNOWLEDGE[k] for k in hindi_hits]
            if matched_replies:
                reply = " ".join(matched_replies)
            else:
                reply = "नमस्ते! मैं EcoAdvisor हूँ। आप गीले-सूखे कचरे, रीसाइक्लिंग या प्लास्टिक निपटान के बारे में कोई भी सवाल पूछ सकते हैं।"
    else:
        # English queries
        detected_lang = "en"
        sources.append("EcoVision Smart Sorter v1.0")

        if any(w in text_lower for w in ["plastic", "bottle", "pet"]):
            reply = (
                "Plastic bottles should be emptied, rinsed, and crushed to save space before being placed into "
                "the Blue Recycling Bin. Bottle caps can be left screwed on. Avoid single-use thin film bags."
            )
        elif any(w in text_lower for w in ["paper", "cardboard", "box", "carton"]):
            reply = (
                "Flatten cardboard boxes and keep paper dry and unsoiled. Greasy pizza boxes should have clean tops "
                "recycled, while heavily greasy sections should go to organic composting."
            )
        elif any(w in text_lower for w in ["organic", "food", "compost", "wet waste"]):
            reply = (
                "Organic food waste, vegetable peels, coffee grounds, and tea leaves belong in the Green Bin. "
                "They can also be diverted into home or community aerobic composters."
            )
        elif any(w in text_lower for w in ["glass", "jar"]):
            reply = (
                "Glass is 100% recyclable indefinitely. Rinse containers clean and drop them in the glass stream or Blue Bin. "
                "Never mix ceramics, mirrors, or light bulbs with container glass."
            )
        elif any(w in text_lower for w in ["battery", "e-waste", "electronics", "phone", "charger", "laptop"]):
            reply = (
                "⚠️ Safety Alert: Never discard lithium batteries or electronics in general household trash. "
                "They pose serious fire and chemical hazards. Deposit them at dedicated Red bins or certified municipal e-waste kiosks."
            )
        elif any(w in text_lower for w in ["aluminium", "aluminum", "can", "tin"]):
            reply = (
                "Aluminium cans are highly recyclable and save up to 95% energy when re-melted. "
                "Empty liquid contents, lightly crush, and place in the Metals / Blue Bin."
            )
        elif any(w in text_lower for w in ["cloth", "textile", "clothes"]):
            reply = (
                "Wearable clothing can be donated to community shelters. Damaged textiles should be kept dry and dropped off "
                "at dedicated textile recycling bins."
            )
        elif any(w in text_lower for w in ["point", "reward", "token", "leaderboard", "badge"]):
            reply = (
                "You earn 10-25 EcoPoints for every verified waste scan, and 20 points for reporting public waste hotspots! "
                "Points can be redeemed for tree planting, bamboo merchandise, and transit vouchers in the Rewards section."
            )
        elif any(w in text_lower for w in ["report", "hotspot", "dump", "overflow"]):
            reply = (
                "If you spot unattended garbage dumps or overflowing bins in your area, use the 'Report Issue' feature to "
                "take a picture with GPS coordinates. Municipal authorities will review and route collectors to resolve it."
            )
        elif any(w in text_lower for w in ["hi", "hello", "hey", "help", "who are you"]):
            reply = (
                "Hello! I'm EcoAdvisor, your AI assistant for circular waste management and sustainable living. "
                "Ask me about sorting specific items, local recycling hubs, composting, or how to earn EcoPoints!"
            )
        else:
            reply = (
                "Proper waste segregation is key: Green bin for wet/biodegradable waste, Blue bin for dry/recyclables "
                "(paper, plastic, metal, glass), and Red container for hazardous/electronic waste. "
                "Which specific item would you like guidance on?"
            )

    return ChatResponse(
        reply=reply,
        sources=sources,
        language_detected=detected_lang,
    )
