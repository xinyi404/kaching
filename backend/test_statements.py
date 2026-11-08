"""Automated tests for statement parsing, AI extraction, and deduplication."""

import io
from datetime import datetime
from decimal import Decimal

import openpyxl
import pypdf
from app.database import SessionLocal
from app.models import Transaction
from app.schemas import StatementExtractionResult, ExtractedStatementTransaction
from app.statement_parser import parse_statement_file
from app.statement_service import process_statement_transactions, process_multiple_statements, parse_datetime_safe


def test_date_parsing():
    print("Testing date parsing...")
    assert parse_datetime_safe("2026-10-15").strftime("%Y-%m-%d") == "2026-10-15"
    assert parse_datetime_safe("15/10/2026").strftime("%Y-%m-%d") == "2026-10-15"
    assert parse_datetime_safe("15-10-2026").strftime("%Y-%m-%d") == "2026-10-15"
    assert parse_datetime_safe("15 Oct 2026").strftime("%Y-%m-%d") == "2026-10-15"
    assert parse_datetime_safe("2026-10-15 14:35:22").strftime("%Y-%m-%d %H:%M:%S") == "2026-10-15 14:35:22"
    print("✓ Date parsing tests passed!")


def test_csv_parser():
    print("Testing CSV parser...")
    csv_content = """Date,Transaction Details,Debit (MYR),Credit (MYR),Balance (MYR)
01/10/2026,SALARY CREDITING TECH CORP,,5000.00,8200.00
03/10/2026,DUITNOW QR TO ZUS COFFEE,12.50,,8187.50
05/10/2026,SHELL PETROL STATION,50.00,,8137.50
10/10/2026,TNG RELOAD VIA FPX,100.00,,8037.50
"""
    parsed = parse_statement_file("bank_statement.csv", csv_content.encode("utf-8"))
    assert parsed.file_type == "csv"
    assert "ZUS COFFEE" in parsed.text_content
    assert "5000.00" in parsed.text_content
    print("✓ CSV parser tests passed!")


def test_xlsx_parser():
    print("Testing XLSX parser...")
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Transactions"
    ws.append(["Posting Date", "Description", "Amount", "Type"])
    ws.append(["2026-10-01", "MONTHLY SALARY", 6500.0, "CR"])
    ws.append(["2026-10-02", "VILLAGE GROCER BANGSAR", 145.80, "DR"])
    ws.append(["2026-10-05", "MAXIS HOME FIBRE", 139.0, "DR"])

    stream = io.BytesIO()
    wb.save(stream)
    xlsx_bytes = stream.getvalue()

    parsed = parse_statement_file("maybank_export.xlsx", xlsx_bytes)
    assert parsed.file_type == "xlsx"
    assert "VILLAGE GROCER" in parsed.text_content
    assert "MAXIS" in parsed.text_content
    print("✓ XLSX parser tests passed!")


def test_pdf_parser():
    print("Testing PDF parser...")
    writer = pypdf.PdfWriter()
    # Create a simple PDF in memory using pypdf writer blank page and text
    page = writer.add_blank_page(width=612, height=792)
    stream = io.BytesIO()
    writer.write(stream)
    pdf_bytes = stream.getvalue()

    parsed = parse_statement_file("tng_statement.pdf", pdf_bytes)
    assert parsed.file_type == "pdf"
    assert parsed.raw_pdf_bytes is not None
    print("✓ PDF parser tests passed!")


def test_deduplication_and_service():
    print("Testing deduplication and service processing...")
    db = SessionLocal()
    try:
        # Create a mock extraction
        mock_extraction = StatementExtractionResult(
            institution_name="Maybank",
            statement_period="01 Oct 2026 - 31 Oct 2026",
            currency="MYR",
            transactions=[
                ExtractedStatementTransaction(
                    date="2026-10-01",
                    amount=5000.00,
                    transaction_type="income",
                    currency="MYR",
                    merchant="Tech Corp",
                    category="Salary",
                    description="Monthly salary crediting",
                ),
                ExtractedStatementTransaction(
                    date="2026-10-03",
                    amount=12.50,
                    transaction_type="expense",
                    currency="MYR",
                    merchant="Zus Coffee",
                    category="Food",
                    description="DuitNow QR Payment to Zus Coffee",
                ),
            ],
        )

        # Run with save=False (preview)
        preview_resp = process_statement_transactions(
            db=db,
            user_id=1,
            filename="mock_statement.csv",
            extraction=mock_extraction,
            save=False,
        )
        assert preview_resp.total_extracted == 2
        assert preview_resp.total_saved == 0
        assert preview_resp.total_income == Decimal("5000.00")
        assert preview_resp.total_expense == Decimal("12.50")
        print("✓ Preview mode works properly!")

        # Run with save=True
        save_resp1 = process_statement_transactions(
            db=db,
            user_id=1,
            filename="mock_statement.csv",
            extraction=mock_extraction,
            save=True,
        )
        assert save_resp1.total_extracted == 2
        print(f"Saved {save_resp1.total_saved} new transactions.")

        # Re-run same extraction to test duplicate detection
        save_resp2 = process_statement_transactions(
            db=db,
            user_id=1,
            filename="mock_statement.csv",
            extraction=mock_extraction,
            save=True,
        )
        assert save_resp2.duplicates_skipped == 2
        assert save_resp2.total_saved == 0
        print("✓ Deduplication successfully detected identical transactions!")

        # Clean up test transactions
        test_ids = [t.id for t in save_resp1.transactions if t.id is not None]
        if test_ids:
            db.query(Transaction).filter(Transaction.id.in_(test_ids)).delete(synchronize_session=False)
            db.commit()
            print("✓ Cleaned up test database records.")

    finally:
        db.close()


def test_multiple_statements_processing():
    print("Testing multiple statements batch processing...")
    db = SessionLocal()
    try:
        stmt1 = StatementExtractionResult(
            institution_name="Maybank",
            statement_period="01 Oct 2026 - 31 Oct 2026",
            currency="MYR",
            transactions=[
                ExtractedStatementTransaction(
                    date="2026-10-01",
                    amount=5000.00,
                    transaction_type="income",
                    currency="MYR",
                    merchant="Tech Corp",
                    category="Salary",
                    description="Monthly salary crediting",
                ),
                ExtractedStatementTransaction(
                    date="2026-10-05",
                    amount=100.00,
                    transaction_type="expense",
                    currency="MYR",
                    merchant="Touch n Go Reload",
                    category="Transfer",
                    description="Reload TNG via FPX",
                ),
            ],
        )

        stmt2 = StatementExtractionResult(
            institution_name="Touch n Go eWallet",
            statement_period="01 Oct 2026 - 31 Oct 2026",
            currency="MYR",
            transactions=[
                ExtractedStatementTransaction(
                    date="2026-10-06",
                    amount=15.00,
                    transaction_type="expense",
                    currency="MYR",
                    merchant="Mixue",
                    category="Food",
                    description="QR Payment Mixue",
                ),
            ],
        )

        batch_resp = process_multiple_statements(
            db=db,
            user_id=1,
            statement_records=[
                ("maybank_oct2026.pdf", stmt1, None),
                ("tng_oct2026.csv", stmt2, None),
            ],
            save=True,
        )

        assert batch_resp.total_files == 2
        assert len(batch_resp.file_summaries) == 2
        assert batch_resp.total_extracted == 3
        assert batch_resp.total_saved == 3
        assert "Maybank" in (batch_resp.institution_name or "")
        assert "Touch n Go eWallet" in (batch_resp.institution_name or "")
        print("✓ Batch multi-statement processing works perfectly!")

        # Clean up
        test_ids = [t.id for t in batch_resp.transactions if t.id is not None]
        if test_ids:
            db.query(Transaction).filter(Transaction.id.in_(test_ids)).delete(synchronize_session=False)
            db.commit()
            print("✓ Cleaned up batch test database records.")

    finally:
        db.close()


def test_fastapi_multi_file_upload():
    print("Testing FastAPI multi-file upload endpoint...")
    from fastapi.testclient import TestClient
    from app.main import app

    client = TestClient(app)
    csv1 = b"Date,Description,Debit,Credit\n01/10/2026,Salary,,4000.00\n"
    csv2 = b"Date,Description,Debit,Credit\n02/10/2026,Groceries,85.50,\n"

    response = client.post(
        "/api/v1/statements/upload?save=false",
        files=[
            ("files", ("oct_bank.csv", csv1, "text/csv")),
            ("files", ("oct_wallet.csv", csv2, "text/csv")),
        ],
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["total_files"] == 2
    assert len(data["file_summaries"]) == 2
    assert data["total_extracted"] == 2
    print("✓ FastAPI multi-file upload endpoint passed successfully!")


if __name__ == "__main__":
    test_date_parsing()
    test_csv_parser()
    test_xlsx_parser()
    test_pdf_parser()
    test_deduplication_and_service()
    test_multiple_statements_processing()
    test_fastapi_multi_file_upload()
    print("\nALL UNIT TESTS PASSED!")
