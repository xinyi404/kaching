"""FastAPI application entry point."""

from datetime import datetime, timedelta
from decimal import Decimal
from typing import Annotated

from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from .ai_extractor import extract_transaction_from_notification
from .database import DEFAULT_USER_ID, get_db
from .models import Transaction, User
from .schemas import (
    NotificationPayload,
    StatementUploadResponse,
    SyncResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)
from .statement_extractor import extract_statement_data
from .statement_parser import parse_statement_file
from .statement_service import process_multiple_statements, process_statement_transactions
from .database import Base, engine, SessionLocal

app = FastAPI(title="Personal Finance API", version="0.1.0")


@app.on_event("startup")
def on_startup() -> None:
    # Ensure database tables exist automatically
    Base.metadata.create_all(bind=engine)
    # Ensure default user exists
    with SessionLocal() as db:
        if db.get(User, DEFAULT_USER_ID) is None:
            default_user = User(id=DEFAULT_USER_ID, email="default@kaching.local")
            db.add(default_user)
            db.commit()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Personal Finance API", "docs": "/docs", "health": "/health"}


@app.get("/health")
def health(db: Session = Depends(get_db)) -> dict[str, str]:
    db.execute(text("SELECT 1"))
    return {"status": "ok", "database": "connected"}


def _require_default_user(db: Session) -> int:
    if db.get(User, DEFAULT_USER_ID) is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                f"Configured user ID {DEFAULT_USER_ID} does not exist in "
                "the users table. Create that user or set DEFAULT_USER_ID."
            ),
        )
    return DEFAULT_USER_ID


@app.get("/api/v1/transactions", response_model=list[TransactionResponse])
def list_transactions(
    start_date: datetime | None = Query(None, description="Optional start datetime filter"),
    end_date: datetime | None = Query(None, description="Optional end datetime filter"),
    db: Session = Depends(get_db),
) -> list[Transaction]:
    user_id = _require_default_user(db)
    query = select(Transaction).where(Transaction.user_id == user_id)
    if start_date is not None:
        query = query.where(Transaction.occurred_at >= start_date)
    if end_date is not None:
        query = query.where(Transaction.occurred_at <= end_date)
    query = query.order_by(Transaction.occurred_at.desc(), Transaction.id.desc())
    return list(db.scalars(query))


@app.post(
    "/api/v1/transactions",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_transaction(
    transaction: TransactionCreate,
    db: Session = Depends(get_db),
) -> Transaction:
    user_id = _require_default_user(db)
    record = Transaction(user_id=user_id, **transaction.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@app.put(
    "/api/v1/transactions/{transaction_id}",
    response_model=TransactionResponse,
    status_code=status.HTTP_200_OK,
)
def update_transaction(
    transaction_id: int,
    transaction: TransactionUpdate,
    db: Session = Depends(get_db),
) -> Transaction:
    user_id = _require_default_user(db)
    query = select(Transaction).where(
        Transaction.id == transaction_id,
        Transaction.user_id == user_id,
    )
    record = db.scalar(query)
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction with id {transaction_id} not found.",
        )

    update_data = transaction.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(record, field, value)

    db.commit()
    db.refresh(record)
    return record


@app.delete(
    "/api/v1/transactions/{transaction_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
) -> None:
    user_id = _require_default_user(db)
    query = select(Transaction).where(
        Transaction.id == transaction_id,
        Transaction.user_id == user_id,
    )
    record = db.scalar(query)
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction with id {transaction_id} not found.",
        )
    db.delete(record)
    db.commit()


import threading

_sync_lock = threading.Lock()


@app.post("/api/v1/transactions/sync", response_model=SyncResponse)
def sync_transactions(
    notifications: list[NotificationPayload],
    db: Session = Depends(get_db),
) -> SyncResponse:
    """Accept incoming notifications, extract transactions using Gemini AI, and persist."""
    with _sync_lock:
        user_id = _require_default_user(db)
        saved_count = 0
        two_hours_ago = datetime.now() - timedelta(hours=2)
        seen_in_batch = set()

        for item in notifications:
            print(f"[DEBUG sync] Received: pkg={item.package_name}, title={item.title!r}, text={item.text!r}")
            extracted = extract_transaction_from_notification(
                package_name=item.package_name,
                title=item.title,
                text=item.text,
            )
            print(f"[DEBUG sync] Extracted: {extracted}")
            if not extracted or not extracted.amount:
                continue

            amount = Decimal(str(round(extracted.amount, 2)))

            # In-batch deduplication
            batch_key = (amount, extracted.merchant or "", (item.text or item.title)[:60])
            if batch_key in seen_in_batch:
                continue
            seen_in_batch.add(batch_key)

            # Database deduplication: check against existing records in past 2 hours
            query = select(Transaction).where(
                Transaction.user_id == user_id,
                Transaction.amount == amount,
                Transaction.occurred_at >= two_hours_ago,
            )
            if extracted.merchant:
                query = query.where(
                    (Transaction.merchant == extracted.merchant)
                    | (Transaction.description.like(f"%{extracted.merchant}%"))
                )
            else:
                snippet = (item.text or item.title)[:40]
                if snippet:
                    query = query.where(Transaction.description.like(f"%{snippet}%"))

            existing = db.scalars(query).first()
            if existing:
                print(f"[DEBUG sync] Skipped duplicate transaction: {amount} {extracted.merchant} (matches ID {existing.id})")
                continue

            record = Transaction(
                user_id=user_id,
                amount=amount,
                transaction_type=extracted.transaction_type or "expense",
                currency=extracted.currency or "MYR",
                merchant=extracted.merchant,
                category=extracted.category or "Other",
                description=item.text[:500] if item.text else item.title,
                source=f"notification:{item.package_name}",
                occurred_at=datetime.now(),
            )
            db.add(record)
            db.flush()
            saved_count += 1

        if saved_count > 0:
            db.commit()

        return SyncResponse(
            received=len(notifications),
            saved=saved_count,
            status="processed",
        )


@app.post(
    "/api/v1/statements/upload",
    response_model=StatementUploadResponse,
    status_code=status.HTTP_200_OK,
)
async def upload_statements(
    files: list[UploadFile] = File(default=[]),
    file: UploadFile | None = File(default=None),
    save: bool = Query(
        True,
        description="Whether to immediately save non-duplicate transactions to database",
    ),
    db: Session = Depends(get_db),
) -> StatementUploadResponse:
    """Upload one or multiple bank / eWallet statements (PDF, XLSX, CSV) and extract transactions with AI."""
    user_id = _require_default_user(db)

    uploaded_files: list[UploadFile] = list(files)
    if file is not None and file not in uploaded_files:
        uploaded_files.append(file)

    if not uploaded_files:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No statement files uploaded.",
        )

    allowed_extensions = (".pdf", ".xlsx", ".xls", ".csv", ".txt")
    statement_records = []

    for uf in uploaded_files:
        fname = uf.filename or "statement"
        lower_name = fname.lower()
        if not any(lower_name.endswith(ext) for ext in allowed_extensions):
            statement_records.append(
                (
                    fname,
                    None,
                    "Unsupported file format. Supported formats are PDF (.pdf), Excel (.xlsx, .xls), and CSV (.csv).",
                )
            )
            continue

        content_bytes = await uf.read()
        if not content_bytes:
            statement_records.append((fname, None, "File is empty."))
            continue

        if len(content_bytes) > 25 * 1024 * 1024:
            statement_records.append((fname, None, "File exceeds 25 MB limit."))
            continue

        try:
            parsed = parse_statement_file(fname, content_bytes)
            extraction = extract_statement_data(parsed, fname)
            statement_records.append((fname, extraction, None))
        except Exception as e:
            statement_records.append((fname, None, str(e)))

    successful_extractions = [rec for rec in statement_records if rec[1] is not None]
    if not successful_extractions and statement_records:
        first_error = statement_records[0][2] or "Statement processing error"
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to process statement(s): {first_error}",
        )

    return process_multiple_statements(
        db=db,
        user_id=user_id,
        statement_records=statement_records,
        save=save,
    )

