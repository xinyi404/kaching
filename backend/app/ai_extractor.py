"""AI-powered extraction of transactions using Gemini with local fallback."""

import logging
import re
from typing import Optional

from google import genai
from pydantic import BaseModel, Field

from .database import GEMINI_API_KEY

logger = logging.getLogger(__name__)


class ExtractedTransaction(BaseModel):
    is_transaction: bool = Field(
        description="True if this notification represents a financial transaction (payment, transfer, received money, purchase)."
    )
    amount: Optional[float] = Field(
        default=None, description="The monetary amount of the transaction."
    )
    currency: Optional[str] = Field(
        default="MYR", description="The 3-letter currency code, e.g. MYR, USD, SGD."
    )
    transaction_type: Optional[str] = Field(
        default="expense",
        description="'expense' if money was spent/sent/paid, 'income' if money was received/refunded/credited.",
    )
    merchant: Optional[str] = Field(
        default=None,
        description="The store, company, service, or recipient person (e.g. 'Mixue', 'Zus Coffee', 'Ali bin Abu').",
    )
    category: Optional[str] = Field(
        default="Other",
        description="A broad budget category such as 'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Groceries', or 'Salary'.",
    )


def _guess_category(merchant: str | None, text: str) -> str:
    combined = f"{merchant or ''} {text}".lower()
    if any(k in combined for k in ["mixue", "kfc", "mcd", "food", "restaurant", "cafe", "coffee", "kopitiam", "tealive", "zus", "sushi"]):
        return "Food"
    if any(k in combined for k in ["grab", "petronas", "shell", "mrt", "lrt", "toll", "parking"]):
        return "Transport"
    if any(k in combined for k in ["watsons", "guardian", "shopee", "lazada", "uniqlo", "supermarket", "jaya grocer", "lotus"]):
        return "Shopping"
    if any(k in combined for k in ["tnb", "air", "water", "unifi", "maxis", "celcom", "digi", "bill"]):
        return "Bills"
    return "Other"


def _local_fallback_extract(package_name: str, title: str, text: str) -> ExtractedTransaction | None:
    """Fast local regex/rule extraction used as fallback if AI is rate-limited (429) or offline."""
    combined = f"{title} {text}".strip()
    amount_match = re.search(r"(?:RM|MYR)\s*([0-9]+(?:\.[0-9]{2})?)", combined, re.I)
    if not amount_match:
        return None

    try:
        amount = float(amount_match.group(1))
    except Exception:
        return None

    if amount <= 0:
        return None

    is_income = any(k in combined.lower() for k in ["received", "diterima", "credited", "cashback", "refund"])
    tx_type = "income" if is_income else "expense"

    merchant = None
    m_match = re.search(
        r"(?:transferred to|transfer to|paid to|received from|from|to|kepada|daripada|at)\s+([A-Za-z0-9\s'&.-]{2,50}?)(?:\s+(?:via|using|with|on|from|for|untuk)|\.|$)",
        combined,
        re.I,
    )
    if m_match:
        merchant = m_match.group(1).strip().rstrip(".")

    category = _guess_category(merchant, combined)

    return ExtractedTransaction(
        is_transaction=True,
        amount=amount,
        currency="MYR",
        transaction_type=tx_type,
        merchant=merchant,
        category=category,
    )


import time

_gemini_cooldown_until: float = 0.0

def extract_transaction_from_notification(
    package_name: str, title: str, text: str
) -> ExtractedTransaction | None:
    """Extract transaction details from notification using Gemini AI with local fallback."""
    global _gemini_cooldown_until
    if not (title or text):
        return None

    # If Gemini is in cooldown (e.g. recently rate-limited), bypass directly to fast local fallback
    if time.time() < _gemini_cooldown_until:
        return _local_fallback_extract(package_name, title, text)

    # 1. Try Gemini AI with candidate models
    client = genai.Client(api_key=GEMINI_API_KEY)
    prompt = (
        "Analyze this Android notification and extract transaction data if it is a financial transaction:\n"
        f"App package: {package_name}\n"
        f"Notification Title: {title}\n"
        f"Notification Content: {text}\n"
    )

    for model_name in ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-3.5-flash"]:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": ExtractedTransaction,
                    "temperature": 0.1,
                },
            )

            if response.text:
                extracted = ExtractedTransaction.model_validate_json(response.text)
                if extracted.is_transaction and extracted.amount and extracted.amount > 0:
                    return extracted
        except Exception as e:
            err_str = str(e)
            logger.warning(f"Gemini {model_name} unavailable: {err_str}")
            if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                # Set 60-second circuit breaker so subsequent items in batch don't stall
                _gemini_cooldown_until = time.time() + 60.0
                break
            continue

    # 2. Local fallback if Gemini fails or is rate-limited
    return _local_fallback_extract(package_name, title, text)
