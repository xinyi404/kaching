"""API request and response schemas."""

from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class NotificationPayload(BaseModel):
    """Raw notification fields sent by the Android client."""

    model_config = ConfigDict(extra="forbid")

    package_name: str = Field(min_length=1, max_length=255)
    title: str = Field(default="", max_length=1000)
    text: str = Field(default="", max_length=10_000)


class SyncResponse(BaseModel):
    received: int
    saved: int = 0
    status: str


class TransactionCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    amount: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    transaction_type: Literal["income", "expense"]
    currency: str = Field(default="MYR", min_length=1, max_length=10)
    merchant: str | None = Field(default=None, max_length=255)
    category: str | None = Field(default=None, max_length=100)
    description: str | None = None
    source: str = Field(default="manual", max_length=100)
    occurred_at: datetime


class TransactionUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    amount: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    transaction_type: Literal["income", "expense"] | None = None
    currency: str | None = Field(default=None, min_length=1, max_length=10)
    merchant: str | None = Field(default=None, max_length=255)
    category: str | None = Field(default=None, max_length=100)
    description: str | None = None
    occurred_at: datetime | None = None


class TransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    amount: Decimal
    transaction_type: Literal["income", "expense"]
    currency: str
    merchant: str | None
    category: str | None
    description: str | None
    source: str | None
    occurred_at: datetime
    created_at: datetime


class ExtractedStatementTransaction(BaseModel):
    """Schema for individual transaction extracted by Gemini AI."""

    date: str = Field(
        description="Transaction date in YYYY-MM-DD or YYYY-MM-DD HH:MM:SS format."
    )
    amount: float = Field(
        description="Absolute positive transaction amount (e.g. 25.50)."
    )
    transaction_type: Literal["income", "expense"] = Field(
        description="'expense' if debit/withdrawal/payment/sent. 'income' if credit/deposit/received/salary/refund."
    )
    currency: str = Field(
        default="MYR",
        description="Currency code such as MYR, USD, SGD.",
    )
    merchant: str = Field(
        description="Clean, recognizable merchant or sender/recipient name without transaction reference codes (e.g. 'Touch n Go Reload', 'Zus Coffee', 'Maybank Interest')."
    )
    category: str = Field(
        default="Other",
        description="Budget category: 'Food', 'Transport', 'Shopping', 'Bills', 'Groceries', 'Entertainment', 'Health', 'Salary', 'Investment', 'Transfer', or 'Other'.",
    )
    description: str = Field(
        default="",
        description="Clean description or reference details of the transaction.",
    )


class StatementExtractionResult(BaseModel):
    """Schema for complete Gemini AI extraction of statement."""

    institution_name: str | None = Field(
        default=None,
        description="Name of the bank or eWallet (e.g. 'Maybank', 'CIMB Bank', 'Public Bank', 'RHB Bank', 'Touch n Go eWallet', 'GrabPay', 'Boost').",
    )
    statement_period: str | None = Field(
        default=None,
        description="Detected statement billing period (e.g. '01 Oct 2026 - 31 Oct 2026').",
    )
    account_identifier: str | None = Field(
        default=None,
        description="Masked account or card number (e.g. '****1234').",
    )
    currency: str = Field(
        default="MYR",
        description="Primary currency of the statement.",
    )
    transactions: list[ExtractedStatementTransaction] = Field(
        default_factory=list,
        description="All individual transactions extracted from the statement. Do not include opening/closing balances or summary totals.",
    )


class StatementTransactionItem(BaseModel):
    """Detailed transaction item returned to the client."""

    id: int | None = None
    amount: Decimal
    transaction_type: Literal["income", "expense"]
    currency: str
    merchant: str | None
    category: str | None
    description: str | None
    occurred_at: datetime
    is_duplicate: bool = False


class StatementFileSummary(BaseModel):
    """Summary of extraction results for a single statement file."""

    filename: str
    institution_name: str | None = None
    statement_period: str | None = None
    total_extracted: int = 0
    total_saved: int = 0
    duplicates_skipped: int = 0
    total_income: Decimal = Decimal("0.00")
    total_expense: Decimal = Decimal("0.00")
    error: str | None = None


class StatementUploadResponse(BaseModel):
    """Response returned after uploading and processing one or multiple statements."""

    filename: str
    total_files: int = 1
    institution_name: str | None = None
    statement_period: str | None = None
    account_identifier: str | None = None
    currency: str = "MYR"
    total_extracted: int = 0
    total_saved: int = 0
    duplicates_skipped: int = 0
    total_income: Decimal = Decimal("0.00")
    total_expense: Decimal = Decimal("0.00")
    file_summaries: list[StatementFileSummary] = Field(default_factory=list)
    transactions: list[StatementTransactionItem] = Field(default_factory=list)

