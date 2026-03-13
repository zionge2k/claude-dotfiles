#!/usr/bin/env python3
# /// script
# dependencies = ["openpyxl"]
# ///
"""Merge multiple CSV files into a single XLSX with one sheet per CSV.

Usage:
    uv run merge_to_xlsx.py -o output.xlsx file1.csv file2.csv ...
    uv run merge_to_xlsx.py -o output.xlsx --names "세트A,세트B" file1.csv file2.csv
"""
import argparse
import csv
import sys
from pathlib import Path

from openpyxl import Workbook


def csv_to_sheet(ws, csv_path):
    """Read CSV and write rows to worksheet."""
    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        for row in reader:
            ws.append(row)


def main():
    parser = argparse.ArgumentParser(description="Merge CSVs into XLSX")
    parser.add_argument("csv_files", nargs="+", help="CSV files to merge")
    parser.add_argument("-o", "--output", required=True, help="Output XLSX path")
    parser.add_argument("--names", help="Comma-separated sheet names (default: CSV filenames)")
    args = parser.parse_args()

    if args.names:
        sheet_names = [n.strip() for n in args.names.split(",")]
    else:
        sheet_names = [Path(f).stem for f in args.csv_files]

    if len(sheet_names) != len(args.csv_files):
        print("Error: sheet names count must match CSV files count", file=sys.stderr)
        sys.exit(1)

    wb = Workbook()
    wb.remove(wb.active)

    for name, csv_path in zip(sheet_names, args.csv_files):
        safe_name = name[:31]
        ws = wb.create_sheet(title=safe_name)
        csv_to_sheet(ws, csv_path)
        print(f"  Added sheet: {safe_name} ({csv_path})")

    wb.save(args.output)
    print(f"\nSaved: {args.output}")


if __name__ == "__main__":
    main()
