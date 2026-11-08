"""File parsing utilities for Bank and eWallet statements (PDF, XLSX, CSV)."""

import csv
import io
import logging
from dataclasses import dataclass
from typing import Optional

import openpyxl
import pypdf

logger = logging.getLogger(__name__)


@dataclass
class ParsedStatementContent:
    """Structured text content and optional raw bytes for statement extraction."""

    text_content: str
    file_type: str
    raw_pdf_bytes: Optional[bytes] = None
    is_scanned_pdf: bool = False


def parse_statement_file(filename: str, content_bytes: bytes) -> ParsedStatementContent:
    """Parse statement file based on extension and return structured content."""
    lower_name = filename.lower()

    if lower_name.endswith(".pdf"):
        return _parse_pdf(content_bytes)
    elif lower_name.endswith(".xlsx") or lower_name.endswith(".xlsm") or lower_name.endswith(".xltx"):
        return _parse_xlsx(content_bytes)
    elif lower_name.endswith(".csv") or lower_name.endswith(".txt"):
        return _parse_csv(content_bytes)
    else:
        # Attempt text fallback, or try PDF if magic bytes match %PDF
        if content_bytes.startswith(b"%PDF"):
            return _parse_pdf(content_bytes)
        return _parse_csv(content_bytes)


def _parse_pdf(pdf_bytes: bytes) -> ParsedStatementContent:
    """Extract text from PDF pages using pypdf."""
    try:
        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
        pages_text: list[str] = []

        for idx, page in enumerate(reader.pages):
            text = (page.extract_text() or "").strip()
            if text:
                pages_text.append(f"--- PAGE {idx + 1} ---\n{text}")

        combined_text = "\n\n".join(pages_text).strip()

        # If very little or no text is extracted, it might be a scanned image-only PDF
        if len(combined_text) < 40:
            logger.info("PDF has very little extractable text, flagging for multimodal processing.")
            return ParsedStatementContent(
                text_content=combined_text,
                file_type="pdf",
                raw_pdf_bytes=pdf_bytes,
                is_scanned_pdf=True,
            )

        return ParsedStatementContent(
            text_content=combined_text,
            file_type="pdf",
            raw_pdf_bytes=pdf_bytes,
            is_scanned_pdf=False,
        )
    except Exception as e:
        logger.warning(f"Error parsing PDF with pypdf: {e}. Falling back to raw bytes.")
        return ParsedStatementContent(
            text_content="",
            file_type="pdf",
            raw_pdf_bytes=pdf_bytes,
            is_scanned_pdf=True,
        )


def _parse_xlsx(xlsx_bytes: bytes) -> ParsedStatementContent:
    """Extract text from all sheets of an Excel workbook."""
    try:
        wb = openpyxl.load_workbook(io.BytesIO(xlsx_bytes), data_only=True)
        lines: list[str] = []

        for sheet_name in wb.sheetnames:
            sheet = wb[sheet_name]
            lines.append(f"=== SHEET: {sheet_name} ===")

            for row in sheet.iter_rows(values_only=True):
                # Filter out rows where all cells are None or empty
                if any(cell is not None and str(cell).strip() != "" for cell in row):
                    formatted_cells = [
                        "" if cell is None else str(cell).strip() for cell in row
                    ]
                    lines.append(" | ".join(formatted_cells))

        combined_text = "\n".join(lines).strip()
        return ParsedStatementContent(
            text_content=combined_text,
            file_type="xlsx",
        )
    except Exception as e:
        logger.error(f"Error reading Excel file: {e}")
        raise ValueError(f"Failed to read Excel statement: {e}") from e


def _parse_csv(csv_bytes: bytes) -> ParsedStatementContent:
    """Extract text from CSV with multiple encoding fallbacks."""
    decoded_text: str | None = None
    encodings = ["utf-8-sig", "utf-8", "latin-1", "cp1252", "iso-8859-1"]

    for enc in encodings:
        try:
            decoded_text = csv_bytes.decode(enc)
            break
        except UnicodeDecodeError:
            continue

    if decoded_text is None:
        decoded_text = csv_bytes.decode("utf-8", errors="replace")

    # Clean and parse rows with csv.reader to ensure standardized tabular formatting
    try:
        lines: list[str] = []
        reader = csv.reader(io.StringIO(decoded_text))
        for row in reader:
            if any(cell.strip() for cell in row):
                lines.append(" | ".join(cell.strip() for cell in row))
        cleaned_text = "\n".join(lines).strip()
    except Exception:
        cleaned_text = decoded_text.strip()

    return ParsedStatementContent(
        text_content=cleaned_text,
        file_type="csv",
    )
