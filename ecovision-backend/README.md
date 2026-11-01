# EcoVision AI — Backend

Complete production-grade FastAPI backend for the EcoVision AI platform, providing AI-powered waste classification, civic environmental issue reporting, gamified rewards and leaderboard, interactive geospatial waste hotspot mapping, and multilingual EcoAdvisor assistance.

## Setup
1. `cd ecovision-backend`
2. `python -m venv venv`
3. `venv\Scripts\activate` (Windows) or `source venv/bin/activate` (macOS/Linux)
4. `pip install -r requirements.txt`
5. Copy `.env.example` to `.env`
6. `python run.py`
7. Visit http://localhost:8000/docs

## API Docs
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Roles & Access Control
- `citizen`: default user role, can scan waste, view personalized impact, submit environmental reports, and redeem rewards
- `collector`: field waste collector, can view regional reports and update statuses
- `authority`: municipal official, can inspect reported hotspots and transition report lifecycle (Submitted -> Under Review -> Assigned -> Resolved -> Rejected)
- `admin`: full system administration, hotspot registration, role management, and analytics

## Features & Modules
- **Authentication**: JWT access & refresh token lifecycle, bcrypt password hashing, role-based access control.
- **Waste Scanner**: 10 distinct waste classes, image validation via Pillow, confidence scoring, safety notices for e-waste/batteries, and alternative class suggestions.
- **Civic Reporting**: Real-time reporting with GPS coordinates, photos, and status tracking.
- **Geospatial Maps**: Pune-region seed data, recycling centres, collection points, and Haversine distance proximity filtering.
- **Gamification & Rewards**: Dynamic point transactions, automatic achievement unlocking, and real-time civic leaderboard.
- **EcoAdvisor AI Assistant**: Contextual waste segregation advice with automatic detection and native responses in Marathi, Hindi, and English.
- **Analytics & Impact**: CO2 emissions prevented, recycled mass calculations, and 7-day scan trends.
