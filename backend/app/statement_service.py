"""Service for processing, deduplicating, and persisting statement transactions."""

import logging
import re
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from .models import Transaction
from .schemas import (
    ExtractedStatementTransaction,
    StatementExtractionResult,
    StatementFileSummary,
    StatementTransactionItem,
    StatementUploadResponse,
)

logger = logging.getLogger(__name__)


def parse_datetime_safe(date_str: str) -> datetime:
    """Safely parse various date string representations into a datetime object."""
    date_str = date_str.strip()
    if not date_str:
        return datetime.now()

    # Common format patterns
    formats = [
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%d %H:%M",
        "%Y-%m-%d",
        "%d/%m/%Y %H:%M:%S",
        "%d/%m/%Y %H:%M",
        "%d/%m/%Y",
        "%d-%m-%Y %H:%M:%S",
        "%d-%m-%Y",
        "%d %b %Y %H:%M:%S",
        "%d %b %Y",
        "%d %B %Y",
        "%Y/%m/%d",
        "%Y.%m.%d",
    ]

    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue

    # Try ISO format
    try:
        return datetime.fromisoformat(date_str)
    except ValueError:
        pass

    # Fallback to current datetime if unparseable
    logger.warning(f"Could not parse date string '{date_str}', falling back to now.")
    return datetime.now()


def _is_duplicate_transaction(
    existing_transactions: list[Transaction],
    new_amount: Decimal,
    new_type: str,
    new_date: datetime,
    new_merchant: Optional[str],
    new_description: Optional[str],
) -> bool:
    """Check if transaction matches an existing transaction within a 48-hour tolerance window."""
    target_date = new_date.date()

    for tx in existing_transactions:
        # Check amount and type match
        if tx.amount != new_amount or tx.transaction_type != new_type:
            continue

        # Check date within 2 days (statements often post 1-2 days after notification/authorization)
        tx_date = tx.occurred_at.date()
        day_diff = abs((tx_date - target_date).days)
        if day_diff > 2:
            continue

        # Check merchant or description similarity
        if new_merchant and tx.merchant:
            m1 = re.sub(r"[^a-zA-Z0-9]", "", new_merchant.lower())
            m2 = re.sub(r"[^a-zA-Z0-9]", "", tx.merchant.lower())
            if m1 in m2 or m2 in m1 or m1[:5] == m2[:5]:
                return True

        # Check description similarity
        if new_description and tx.description:
            d1 = re.sub(r"[^a-zA-Z0-9]", "", new_description.lower())
            d2 = re.sub(r"[^a-zA-Z0-9]", "", tx.description.lower())
            if len(d1) > 4 and (d1 in d2 or d2 in d1):
                return True

        # If amount and exact date match with no conflicting merchant info
        if day_diff == 0:
            return True

    return False


def process_multiple_statements(
    db: Session,
    user_id: int,
    statement_records: list[tuple[str, StatementExtractionResult | None, str | None]],
    save: bool = True,
) -> StatementUploadResponse:
    """Process multiple extracted statements together, detecting duplicates across all files."""
    existing_txs = list(
        db.scalars(
            select(Transaction).where(Transaction.user_id == user_id)
        )
    )

    all_items: list[StatementTransactionItem] = []
    file_summaries: list[StatementFileSummary] = []
    total_saved = 0
    total_duplicates_skipped = 0
    total_extracted = 0
    total_income = Decimal("0.00")
    total_expense = Decimal("0.00")

    distinct_institutions: list[str] = []
    distinct_periods: list[str] = []
    filenames: list[str] = []
    primary_currency = "MYR"

    for filename, extraction, error in statement_records:
        filenames.append(filename)

        if error or extraction is None:
            file_summaries.append(
                StatementFileSummary(
                    filename=filename,
                    error=error or "Extraction failed",
                )
            )
            continue

        if extraction.institution_name and extraction.institution_name not in distinct_institutions:
            distinct_institutions.append(extraction.institution_name)

        if extraction.statement_period and extraction.statement_period not in distinct_periods:
            distinct_periods.append(extraction.statement_period)

        if extraction.currency:
            primary_currency = extraction.currency

        file_extracted = 0
        file_saved = 0
        file_dupes = 0
        file_income = Decimal("0.00")
        file_expense = Decimal("0.00")

        source_tag = f"statement:{extraction.institution_name or filename}"[:100]

        for tx in extraction.transactions:
            if not tx.amount or tx.amount <= 0:
                continue

            amount = Decimal(str(round(tx.amount, 2)))
            tx_type = tx.transaction_type.lower()
            if tx_type not in ("income", "expense"):
                tx_type = "expense"

            occurred_at = parse_datetime_safe(tx.date)

            is_dup = _is_duplicate_transaction(
                existing_transactions=existing_txs,
                new_amount=amount,
                new_type=tx_type,
                new_date=occurred_at,
                new_merchant=tx.merchant,
                new_description=tx.description,
            )

            file_extracted += 1
            if tx_type == "income":
                file_income += amount
            else:
                file_expense += amount

            saved_id: Optional[int] = None

            if is_dup:
                file_dupes += 1
            elif save:
                record = Transaction(
                    user_id=user_id,
                    amount=amount,
                    transaction_type=tx_type,
                    currency=tx.currency or extraction.currency or primary_currency,
                    merchant=tx.merchant[:255] if tx.merchant else None,
                    category=tx.category or "Other",
                    description=tx.description[:500] if tx.description else (tx.merchant or ""),
                    source=source_tag,
                    occurred_at=occurred_at,
                )
                db.add(record)
                db.flush()
                saved_id = record.id
                file_saved += 1
                existing_txs.append(record)

            all_items.append(
                StatementTransactionItem(
                    id=saved_id,
                    amount=amount,
                    transaction_type=tx_type,
                    currency=tx.currency or extraction.currency or primary_currency,
                    merchant=tx.merchant,
                    category=tx.category,
                    description=tx.description,
                    occurred_at=occurred_at,
                    is_duplicate=is_dup,
                )
            )

        file_summaries.append(
            StatementFileSummary(
                filename=filename,
                institution_name=extraction.institution_name,
                statement_period=extraction.statement_period,
                total_extracted=file_extracted,
                total_saved=file_saved,
                duplicates_skipped=file_dupes,
                total_income=file_income,
                total_expense=file_expense,
            )
        )

        total_extracted += file_extracted
        total_saved += file_saved
        total_duplicates_skipped += file_dupes
        total_income += file_income
        total_expense += file_expense

    if save and total_saved > 0:
        db.commit()

    all_items.sort(key=lambda x: x.occurred_at, reverse=True)

    combined_institutions = ", ".join(distinct_institutions) if distinct_institutions else None
    combined_periods = ", ".join(distinct_periods) if distinct_periods else None
    if len(filenames) == 1:
        display_filename = filenames[0]
    else:
        display_filename = f"{len(filenames)} statements ({', '.join(filenames[:3])}{'...' if len(filenames) > 3 else ''})"

    return StatementUploadResponse(
        filename=display_filename,
        total_files=len(filenames),
        institution_name=combined_institutions,
        statement_period=combined_periods,
        account_identifier=None,
        currency=primary_currency,
        total_extracted=total_extracted,
        total_saved=total_saved,
        duplicates_skipped=total_duplicates_skipped,
        total_income=total_income,
        total_expense=total_expense,
        file_summaries=file_summaries,
        transactions=all_items,
    )


def process_statement_transactions(
    db: Session,
    user_id: int,
    filename: str,
    extraction: StatementExtractionResult,
    save: bool = True,
) -> StatementUploadResponse:
    """Process a single statement extraction."""
    return process_multiple_statements(
        db=db,
        user_id=user_id,
        statement_records=[(filename, extraction, None)],
        save=save,
    )
