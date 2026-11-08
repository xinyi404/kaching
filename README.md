# Kaching — Personal Finance Tracker

> *"Your money, in focus"*

**Kaching** is an intelligent, local-first personal finance tracking platform built with **Flutter** (Android / Web / Desktop) and a high-performance **FastAPI** backend powered by **Google Gemini AI**.

It seamlessly automates personal finance management through on-device bank notification capture, multi-format bank statement ingestion (PDF, Excel, CSV, TXT), AI-powered categorization, interactive analytics, and full transaction customization.

---

## Table of Contents

- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [API Overview](#api-overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Running Automated Tests](#running-automated-tests)
- [Database Schema](#database-schema)
- [License](#license)

---

## Key Features

### 1. Automated Transaction Ingestion
- **On-Device Notification Capture:** Automatically listens to incoming bank notifications (e.g. Maybank, CIMB, Touch 'n Go, GrabPay, Public Bank) on Android using `notification_listener_service`.
- **Local-First Offline Queue:** Captures notifications locally in SQLite (`sqflite`) before syncing with the backend, ensuring zero data loss even when offline.
- **Background Sync:** Periodically syncs pending notifications via `workmanager`.

### 2. Google Gemini AI Transaction Extraction
- **Smart Notification Parsing:** Extracts amount, currency, transaction type (`expense` or `income`), merchant/source, timestamp, and intelligent category classification using Gemini AI (`gemini-2.5-flash`).
- **Multi-Format Bank Statement Processing:** Batch upload statements in **PDF**, **Excel (`.xlsx`, `.xls`)**, **CSV**, or **TXT**.
- **Automated Deduplication:** Detects and skips existing transactions based on cryptographic fingerprinting and similarity matching.

### 3. Financial Analytics & Visualizations
- **Cash Flow Trends Bar Chart:** Interactive bar chart comparing **Income vs. Expenses** with net cash flow indicators.
- **Dynamic Granularity:** Switch seamlessly between **Daily**, **Monthly** (default), and **Yearly** views.
- **Spending by Category Donut Chart:** Visual breakdown of expenses by category with percentage distribution and custom color coding.
- **Real-Time Financial Metrics:** Period summary KPIs including Total Income, Total Expenses, Net Balance, and transaction counts.

### 4. Search & Filter Engine
- **Date Range Presets:** Filter transactions by `Today`, `Yesterday`, `Last 7 days`, `This Month` (default), `Last Month`, `Last 3 months`, and `All Time`.
- **Custom Date Picker:** Pick precise start and end dates with custom boundaries.
- **Type Filter Chips:** Instant switching between `All`, `Expenses`, and `Income`.
- **Multi-Field Real-Time Search:** Search dynamically by merchant name, category, or note/description.

### 5. Manual Recording & Detail Editing
- **Manual Entry:** Add transactions with customizable categories (including inline category creation directly from dropdown).
- **Edit Recorded Details:** Tap any transaction in the dashboard or transaction list to adjust mislabeled categories, swap between Income and Expense, modify amounts, update merchants, adjust dates, or edit notes.
- **Deletion with Confirmation:** Securely remove accidental or unwanted transaction records.

---

## System Architecture

```
┌────────────────────────────────────────────────────────┐
│               Android / Client Device                 │
│                                                        │
│  ┌───────────────────────┐   ┌──────────────────────┐  │
│  │ Notification Listener │──>│ Local SQLite Queue   │  │
│  └───────────────────────┘   └──────────┬───────────┘  │
│                                         │ (Sync)       │
│  ┌───────────────────────┐              ▼              │
│  │ Flutter UI (Material3)│◄─────► REST API Client      │
│  └───────────────────────┘                             │
└─────────────────────────────────────────┼──────────────┘
                                          │ HTTP / JSON
                                          ▼
┌────────────────────────────────────────────────────────┐
│                 FastAPI Backend                        │
│                                                        │
│  ┌───────────────────────┐   ┌──────────────────────┐  │
│  │ Statement Parser      │   │ Gemini AI Extractor  │  │
│  │ (PDF/Excel/CSV/TXT)   │──>│ (gemini-2.5-flash)   │  │
│  └───────────────────────┘   └──────────┬───────────┘  │
│                                         ▼              │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Deduplication & Normalization Service            │  │
│  └──────────────────────┬───────────────────────────┘  │
│                         ▼                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │ SQLAlchemy 2.0 ORM (MySQL / SQLite)              │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Frontend (Mobile & Desktop)
- **Framework:** [Flutter](https://flutter.dev) (Dart SDK `>=3.3.0 <4.0.0`)
- **UI Design:** Custom Material 3 theme (`FinanceColors`: Ink `#1E252B`, Sand `#E8E2D9`, Coral Red `#E25241`, Indigo Blue `#255C99`)
- **Local Persistence:** `sqflite`, `path_provider`
- **Background Processing:** `workmanager`
- **Native Android Interop:** `notification_listener_service`
- **File Ingestion:** `file_picker`
- **Networking:** `http`

### Backend (Server)
- **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python 3.12+)
- **ASGI Server:** [Uvicorn](https://www.uvicorn.org/)
- **ORM & Database:** [SQLAlchemy 2.0](https://www.sqlalchemy.org/) with [PyMySQL](https://github.com/PyMySQL/PyMySQL) (MySQL 8.0+)
- **Validation & Schemas:** [Pydantic v2](https://docs.pydantic.dev/)
- **Generative AI:** [Google GenAI SDK](https://github.com/google-gemini/generative-ai-python) (`google-genai`)
- **Document Parsers:** `pypdf`, `openpyxl`, Python `csv`

---

## Repository Structure

```
kaching/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── ai_extractor.py         # Google Gemini AI extraction logic
│   │   ├── database.py             # SQLAlchemy engine & session setup
│   │   ├── main.py                 # FastAPI endpoints & route handlers
│   │   ├── models.py               # Database ORM models (User, Transaction)
│   │   ├── schemas.py              # Pydantic request/response schemas
│   │   ├── statement_extractor.py  # Regex & text extraction for bank statements
│   │   ├── statement_parser.py     # Binary parsers for PDF, XLSX, CSV, TXT
│   │   └── statement_service.py    # Deduplication and batch transaction persistence
│   ├── requirements.txt            # Python dependencies
│   └── test_statements.py          # Backend statement & API test suite
│
├── frontend/
│   ├── android/                    # Android project configuration & permissions
│   ├── lib/
│   │   ├── all_transactions_page.dart # Full transaction list & filter page
│   │   ├── api_service.dart        # HTTP client for backend REST API
│   │   ├── background_sync.dart    # WorkManager background sync logic
│   │   ├── database_helper.dart    # Local SQLite notification queue
│   │   ├── date_range_picker_dialog.dart # Custom date filter modal
│   │   ├── main.dart               # App entry point, dashboard, Add/Edit sheet
│   │   ├── notification_capture.dart # Native notification listener setup
│   │   ├── stats_bar_chart.dart    # Dynamic Cash Flow Trends Bar Chart
│   │   └── sync_service.dart       # Local-to-remote notification synchronization
│   ├── test/
│   │   ├── all_transactions_test.dart
│   │   ├── category_creation_test.dart
│   │   ├── edit_transaction_test.dart
│   │   ├── statement_import_test.dart
│   │   ├── stats_bar_chart_test.dart
│   │   └── widget_test.dart
│   ├── pubspec.yaml                # Flutter dependencies and project metadata
│   └── analysis_options.yaml       # Dart analyzer rules
│
└── README.md                       # Main project documentation
```

---

## API Overview

All transactional endpoints are prefixed under `/api/v1`:

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Healthcheck and database connectivity test |
| `GET` | `/api/v1/transactions` | Retrieve transactions (supports `start_date` and `end_date` query params) |
| `POST` | `/api/v1/transactions` | Manually record a new transaction |
| `PUT` | `/api/v1/transactions/{id}` | Update an existing transaction's details (category, type, amount, merchant, notes) |
| `DELETE` | `/api/v1/transactions/{id}` | Permanently delete a transaction |
| `POST` | `/api/v1/notifications/process` | Real-time notification parsing with Gemini AI |
| `POST` | `/api/v1/notifications/sync` | Batch synchronization of queued notifications from mobile device |
| `POST` | `/api/v1/statements/upload` | Multi-file upload for bank statements (PDF, Excel, CSV, TXT) with deduplication |

---

## Getting Started

### Prerequisites

- **Python:** 3.12 or newer
- **Flutter SDK:** 3.3.0 or newer
- **Database:** MySQL 8.0+ (or SQLite for local testing)
- **Google Gemini API Key:** Access to Gemini 2.5 Flash

---

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate a Python virtual environment:**
   ```bash
   # Windows
   python -m venv .venv
   .venv\Scripts\activate

   # macOS / Linux
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables:**
   Create a `.env` file or export the following variables:
   ```env
   DATABASE_URL=mysql+pymysql://<user>:<password>@127.0.0.1:3306/kaching?charset=utf8mb4
   DEFAULT_USER_ID=1
   GEMINI_API_KEY=<your-google-gemini-api-key>
   ```

5. **Initialize Database:**
   Ensure your MySQL server has a database named `kaching` and a default user in the `users` table:
   ```sql
   CREATE DATABASE IF NOT EXISTS kaching CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   USE kaching;
   INSERT INTO users (id, email) VALUES (1, 'user@example.com') ON DUPLICATE KEY UPDATE id=id;
   ```

6. **Start the FastAPI server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   Interactive Swagger documentation will be available at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

---

### Frontend Setup

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure API Host (if running on Android Emulator or physical device):**
   In `frontend/lib/api_service.dart`, verify `apiBaseUrl`:
   - Android Emulator: `http://10.0.2.2:8000`
   - Local Machine / Desktop: `http://127.0.0.1:8000`
   - Physical Device: `http://<YOUR_LAN_IP>:8000`

4. **Launch the application:**
   ```bash
   flutter run
   ```

---

## Running Automated Tests

### Backend Unit & Integration Tests
Run the automated statement parser, AI extraction, deduplication, and endpoint tests:
```bash
cd backend
python test_statements.py
```

### Frontend Widget & Unit Tests
Run all widget tests (including chart rendering, filtering, editing, and statement imports):
```bash
cd frontend
flutter test
```

### Static Analysis
Run Dart analyzer to verify code quality:
```bash
cd frontend
flutter analyze
```

---

## Database Schema

```sql
-- User Account
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Normalized Transaction Records
CREATE TABLE transaction_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    transaction_type VARCHAR(45) NOT NULL DEFAULT 'expense',
    currency VARCHAR(10) NOT NULL,
    merchant VARCHAR(255) NULL,
    category VARCHAR(100) NULL,
    description TEXT NULL,
    source VARCHAR(100) NULL,
    occurred_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## License

This project is proprietary and intended for personal finance tracking. All rights reserved.
