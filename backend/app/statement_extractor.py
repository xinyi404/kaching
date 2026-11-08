"""AI-powered extraction of bank and eWallet statements using Gemini with resilient fallbacks."""

import logging
import re
from typing import Optional

from google import genai
from google.genai import types

from .database import GEMINI_API_KEY
from .schemas import ExtractedStatementTransaction, StatementExtractionResult
from .statement_parser import ParsedStatementContent

logger = logging.getLogger(__name__)

# List of models to try in order of preference
GEMINI_MODELS = [
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite",
    "gemini-3.5-flash",
]

EXTRACTION_SYSTEM_PROMPT = """You are an expert financial document and statement parsing AI.
Your task is to analyze bank account statements or eWallet statements (PDF, Excel, or CSV) and extract all individual financial transactions into clean, structured data.

GUIDELINES FOR EXTRACTION:
1. Identify Statement Metadata:
   - Institution name (e.g., 'Maybank', 'CIMB Bank', 'Public Bank', 'RHB Bank', 'Hong Leong Bank', 'Touch n Go eWallet', 'GrabPay', 'Boost', 'BigPay', 'ShopeePay', 'Wise', 'HSBC', etc.).
   - Statement period if mentioned (e.g. '01 Oct 2026 - 31 Oct 2026').
   - Account or wallet identifier (e.g. masked account number like '****5678').
   - Default currency (usually 'MYR' for Malaysian banks/eWallets, or USD/SGD/EUR etc.).

2. Extract EVERY Individual Transaction:
   - date: Normalize date into 'YYYY-MM-DD' or 'YYYY-MM-DD HH:MM:SS'. If only DD/MM or DD-Mon is printed on the row, use the statement month and year from the document header.
   - amount: Absolute positive number (e.g. 35.80). Never negative.
   - transaction_type:
     * 'expense' if it represents money leaving the account: Debit (DR), Withdrawal, Outward Transfer, DuitNow QR Payment, Purchase, Fee, Bill Payment, Reloading another service.
     * 'income' if it represents money entering the account: Credit (CR), Deposit, Inward Transfer, Salary, Dividend, Profit/Interest Paid, Cashback, Refund, eWallet Top-up.
   - currency: 3-letter currency code (e.g. 'MYR').
   - merchant: Clean, human-readable name of the merchant, recipient, sender, or platform.
     * Strip technical prefixes like 'DUITNOW TRF TO', 'IBG REF', 'POS DEBIT', 'FPX PAYMENT', 'QR PAY', 'MYDEBIT', transaction IDs, or terminal numbers.
     * Examples: 'DUITNOW TO ZUS COFFEE REF: 98124' -> 'Zus Coffee'
     * 'SHELL JALAN AMPANG KUALA LUMPUR' -> 'Shell'
     * 'SHOPEEPAY MY KUALA LUMPUR' -> 'ShopeePay'
     * 'SALARY CREDITING TECH CORP' -> 'Tech Corp (Salary)'
     * 'TOUCH N GO E-WALLET RELOAD' -> 'Touch n Go Reload'
   - category: Assign the most fitting category:
     * 'Food': Restaurants, cafes, food delivery (GrabFood, Foodpanda), groceries/supermarkets (Lotus's, Jaya Grocer, 99 Speedmart if grocery).
     * 'Transport': Petrol/Gas (Shell, Petronas), Tolls, Grab rides, parking, train/transit.
     * 'Shopping': Retail, clothing, online shopping (Shopee, Lazada, TikTok Shop).
     * 'Bills': Utilities (TNB, Syabas/Air), Telco (Maxis, Celcom, Digi, Unifi), subscriptions (Netflix, Spotify).
     * 'Groceries': Supermarkets, hypermarkets, wet markets.
     * 'Entertainment': Movies, games, hobbies.
     * 'Health': Clinics, pharmacy, hospitals.
     * 'Salary': Monthly salary, wages, allowances.
     * 'Investment': Stocks, ASB, crypto, mutual funds, deposit interest.
     * 'Transfer': General peer-to-peer transfers to friends/family without a commercial merchant.
     * 'Other': Fees, taxes, uncategorized transactions.
   - description: Clear summary or raw reference note from the statement.

3. STRICT EXCLUSIONS:
   - DO NOT include Opening/Beginning Balance, Closing/Ending Balance, Total Debit, Total Credit, or Available Balance rows.
   - DO NOT include promotional text, contact numbers, or legal disclaimers.
"""


def extract_statement_data(
    parsed_content: ParsedStatementContent,
    filename: str = "",
) -> StatementExtractionResult:
    """Send statement text or PDF bytes to Gemini AI with multi-model fallback and heuristic backup."""
    client = genai.Client(api_key=GEMINI_API_KEY)

    prompt = (
        f"{EXTRACTION_SYSTEM_PROMPT}\n\n"
        f"File name: {filename}\n"
        f"File format: {parsed_content.file_type.upper()}\n\n"
    )

    contents: list = []

    # If it is a scanned/image PDF, send PDF bytes directly
    if parsed_content.is_scanned_pdf and parsed_content.raw_pdf_bytes:
        logger.info("Using multimodal PDF extraction with Gemini")
        contents.append(
            types.Part.from_bytes(
                data=parsed_content.raw_pdf_bytes,
                mime_type="application/pdf",
            )
        )
        contents.append(
            prompt + "Please analyze the attached PDF statement and extract all transactions."
        )
    else:
        prompt += (
            "Here is the text extracted from the statement:\n"
            "```\n"
            f"{parsed_content.text_content}\n"
            "```\n\n"
            "Extract all transactions accurately according to the instructions."
        )
        contents.append(prompt)

    last_error: Exception | None = None

    # Try candidate models with fallback
    for model_name in GEMINI_MODELS:
        try:
            logger.info(f"Attempting extraction with model: {model_name}")
            response = client.models.generate_content(
                model=model_name,
                contents=contents,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": StatementExtractionResult,
                    "temperature": 0.1,
                },
            )

            if response.text:
                result = StatementExtractionResult.model_validate_json(response.text)
                logger.info(
                    f"Successfully extracted {len(result.transactions)} transactions using {model_name}"
                )
                return result

        except Exception as e:
            logger.warning(f"Model {model_name} failed: {e}. Trying next model...")
            last_error = e
            continue

    # If all AI models failed, attempt heuristic tabular extraction for CSV/XLSX text
    logger.warning("All Gemini models exhausted or failed. Attempting heuristic fallback extraction.")
    fallback_result = _heuristic_tabular_fallback(parsed_content.text_content, filename)
    if fallback_result and fallback_result.transactions:
        logger.info(f"Heuristic fallback recovered {len(fallback_result.transactions)} transactions.")
        return fallback_result

    if last_error:
        raise RuntimeError(f"AI statement extraction failed: {last_error}") from last_error

    return StatementExtractionResult(
        institution_name=None,
        statement_period=None,
        transactions=[],
    )


def _heuristic_tabular_fallback(text: str, filename: str) -> Optional[StatementExtractionResult]:
    """Resilient rule-based parser for CSV / pipe-delimited statement exports when AI is unavailable."""
    if not text:
        return None

    lines = [line.strip() for line in text.split("\n") if line.strip()]
    if len(lines) < 2:
        return None

    transactions: list[ExtractedStatementTransaction] = []
    institution = "Bank Statement"
    if "maybank" in filename.lower() or "maybank" in text.lower():
        institution = "Maybank"
    elif "cimb" in filename.lower() or "cimb" in text.lower():
        institution = "CIMB Bank"
    elif "tng" in filename.lower() or "touch 'n go" in text.lower():
        institution = "Touch 'n Go eWallet"
    elif "grab" in filename.lower() or "grabpay" in text.lower():
        institution = "GrabPay"

    # Search for header row
    header_idx = -1
    for idx, line in enumerate(lines[:15]):
        lower = line.lower()
        if "date" in lower and ("amount" in lower or "debit" in lower or "credit" in lower or "description" in lower):
            header_idx = idx
            break

    if header_idx == -1:
        return None

    headers = [h.strip().lower() for h in re.split(r"[,|]", lines[header_idx])]

    # Find column indices
    date_col = -1
    desc_col = -1
    debit_col = -1
    credit_col = -1
    amount_col = -1
    type_col = -1

    for i, h in enumerate(headers):
        if "date" in h and date_col == -1:
            date_col = i
        elif any(k in h for k in ["desc", "detail", "particular", "merchant"]) and desc_col == -1:
            desc_col = i
        elif "debit" in h or "withdrawal" in h or "keluar" in h:
            debit_col = i
        elif "credit" in h or "deposit" in h or "masuk" in h:
            credit_col = i
        elif "amount" in h and amount_col == -1:
            amount_col = i
        elif "type" in h:
            type_col = i

    for line in lines[header_idx + 1:]:
        cells = [c.strip() for c in re.split(r"[,|]", line)]
        if len(cells) < max(date_col, desc_col, 1) + 1:
            continue

        raw_date = cells[date_col] if date_col != -1 and date_col < len(cells) else ""
        raw_desc = cells[desc_col] if desc_col != -1 and desc_col < len(cells) else ""

        # Validate date pattern
        if not re.search(r"\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}", raw_date):
            continue

        amount = 0.0
        tx_type = "expense"

        if debit_col != -1 and debit_col < len(cells) and cells[debit_col]:
            val = re.sub(r"[^0-9.]", "", cells[debit_col])
            if val:
                amount = float(val)
                tx_type = "expense"
        elif credit_col != -1 and credit_col < len(cells) and cells[credit_col]:
            val = re.sub(r"[^0-9.]", "", cells[credit_col])
            if val:
                amount = float(val)
                tx_type = "income"
        elif amount_col != -1 and amount_col < len(cells) and cells[amount_col]:
            val = re.sub(r"[^0-9.]", "", cells[amount_col])
            if val:
                amount = float(val)
                if "-" in cells[amount_col] or "dr" in cells[amount_col].lower():
                    tx_type = "expense"
                elif "+" in cells[amount_col] or "cr" in cells[amount_col].lower():
                    tx_type = "income"
                elif type_col != -1 and type_col < len(cells):
                    t_str = cells[type_col].lower()
                    tx_type = "income" if ("cr" in t_str or "in" in t_str) else "expense"

        if amount <= 0:
            continue

        # Clean merchant name
        clean_merchant = re.sub(
            r"^(duitnow|qr pay|ibg|fpx|pos debit|mydebit|trf to|payment to)\s*",
            "",
            raw_desc,
            flags=re.IGNORECASE,
        ).strip()
        if not clean_merchant:
            clean_merchant = raw_desc or "Transaction"

        # Guess category
        desc_lower = raw_desc.lower()
        category = "Other"
        if any(w in desc_lower for w in ["salary", "gaji", "bonus", "payroll"]):
            category = "Salary"
            tx_type = "income"
        elif any(w in desc_lower for w in ["mcdonald", "kfc", "zus", "starbucks", "food", "cafe", "restaurant", "mixue"]):
            category = "Food"
        elif any(w in desc_lower for w in ["shell", "petronas", "petrol", "caltex", "grab ride", "touch n go", "tng", "toll"]):
            category = "Transport"
        elif any(w in desc_lower for w in ["shopee", "lazada", "tiktok", "uniqlo", "zara"]):
            category = "Shopping"
        elif any(w in desc_lower for w in ["tnb", "tenaga", "maxis", "celcom", "digi", "unifi", "water", "syabas", "bill"]):
            category = "Bills"
        elif any(w in desc_lower for w in ["grocer", "jaya grocer", "lotus", "speedmart", "village grocer"]):
            category = "Groceries"

        transactions.append(
            ExtractedStatementTransaction(
                date=raw_date,
                amount=amount,
                transaction_type=tx_type,
                currency="MYR",
                merchant=clean_merchant[:100],
                category=category,
                description=raw_desc[:200],
            )
        )

    if not transactions:
        return None

    return StatementExtractionResult(
        institution_name=institution,
        statement_period=None,
        currency="MYR",
        transactions=transactions,
    )
