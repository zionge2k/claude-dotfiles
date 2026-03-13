#!/usr/bin/env python3
"""Collect single item data from domeggook API and save as JSON.

Usage:
    python3 collect_single_items.py "슬림 파우치"
    python3 collect_single_items.py "슬림 파우치" -o my_output.json
    python3 collect_single_items.py "슬림 파우치" --cg 01_07_00_00_00
"""
import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime

API_KEY = os.environ.get("DOMEGGOOK_API_KEY", "")
if not API_KEY:
    print("Error: DOMEGGOOK_API_KEY environment variable is not set", file=sys.stderr)
    sys.exit(1)

BASE_URL = "https://domeggook.com/ssl/api/"
API_DELAY = 0.3


def api_get(params):
    url = BASE_URL + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"  [API ERROR] {e}", file=sys.stderr)
        return None


def search_items(keyword, page=1, size=200, category=None, sgd=True, fdl=True):
    params = {
        "ver": "4.1",
        "mode": "getItemList",
        "aid": API_KEY,
        "market": "dome",
        "om": "json",
        "kw": keyword,
        "sgd": "true" if sgd else "false",
        "fdl": "true" if fdl else "false",
        "mxq": 1,
        "sz": size,
        "pg": page,
        "so": "rd",
    }
    if category:
        params["cg"] = category
    return api_get(params)


def get_item_detail(item_no):
    params = {
        "ver": "4.5",
        "mode": "getItemView",
        "aid": API_KEY,
        "no": item_no,
        "om": "json",
    }
    data = api_get(params)
    if data:
        return data.get("domeggook", data)
    return None


def safe_get(d, *keys, default=""):
    current = d
    for key in keys:
        if isinstance(current, dict):
            current = current.get(key, default)
        else:
            return default
    return current if current is not None else default


def is_true(val):
    if isinstance(val, bool):
        return val
    return str(val).lower() == "true"


def parse_price(price_val):
    if isinstance(price_val, (int, float)):
        return int(price_val)
    if isinstance(price_val, str):
        if "+" in price_val:
            try:
                return int(price_val.split("|")[0].split("+")[1])
            except (IndexError, ValueError):
                return 0
        try:
            return int(price_val)
        except ValueError:
            return 0
    return 0


def parse_deli_fee(deli_data):
    dome = deli_data.get("dome", {}) if isinstance(deli_data, dict) else {}
    if not isinstance(dome, dict):
        return 0
    fee = dome.get("fee")
    if fee:
        try:
            return int(fee)
        except (ValueError, TypeError):
            pass
    tbl = dome.get("tbl")
    if tbl and isinstance(tbl, str) and "+" in tbl:
        try:
            return int(tbl.split("|")[0].split("+")[1])
        except (IndexError, ValueError):
            pass
    return 0


def extract_item(data, item_no):
    """Extract structured item data from detail API response."""
    parents_elem = safe_get(data, "category", "parents", "elem", default=[])
    current_name = safe_get(data, "category", "current", "name", default="")
    cat_names = []
    if isinstance(parents_elem, list):
        for p in parents_elem:
            if isinstance(p, dict):
                cat_names.append(p.get("name", ""))
    elif isinstance(parents_elem, dict):
        cat_names.append(parents_elem.get("name", ""))
    cat_names.append(str(current_name))
    cat_path = " > ".join(n for n in cat_names if n)

    kw_data = safe_get(data, "basis", "keywords", "kw", default="")
    if isinstance(kw_data, list):
        keywords = ", ".join(str(k) for k in kw_data)
    elif isinstance(kw_data, str):
        keywords = kw_data
    else:
        keywords = ""

    return {
        "no": str(item_no),
        "title": safe_get(data, "basis", "title", default=""),
        "category": cat_path,
        "price_dome": parse_price(safe_get(data, "price", "dome", default=0)),
        "price_supply": parse_price(safe_get(data, "price", "supply", default=0)),
        "deli_fee": parse_deli_fee(data.get("deli", {})),
        "seller_id": safe_get(data, "seller", "id", default=""),
        "seller_nick": safe_get(data, "seller", "nick", default=""),
        "seller_good": is_true(safe_get(data, "seller", "good", default="false")),
        "seller_score_avg": safe_get(data, "seller", "score", "avg", default=""),
        "seller_score_cnt": safe_get(data, "seller", "score", "cnt", default=""),
        "moq": int(safe_get(data, "qty", "domeMoq", default=0) or 0),
        "fast_deli": is_true(safe_get(data, "deli", "fastDeli", default="false")),
        "thumbnail": safe_get(data, "thumb", "original", default=""),
        "url_dome": f"https://domeggook.com/{item_no}",
        "url_domeme": f"https://domeme.domeggook.com/s/{item_no}",
        "keywords": keywords,
    }


def main():
    parser = argparse.ArgumentParser(description="Collect single item sourcing data")
    parser.add_argument("keyword", help="Search keyword")
    parser.add_argument("-o", "--output", help="Output JSON file path")
    parser.add_argument("--cg", help="Category code (e.g., 01_07_00_00_00)")
    parser.add_argument("--no-sgd", action="store_true", help="Include non-good sellers")
    parser.add_argument("--no-fdl", action="store_true", help="Include non-fast-delivery")
    args = parser.parse_args()

    keyword = args.keyword
    safe_keyword = keyword.replace(" ", "")
    today = datetime.now().strftime("%Y-%m-%d")
    output_path = args.output or f"{safe_keyword}_단품_{today}.json"

    sgd = not args.no_sgd
    fdl = not args.no_fdl

    # Step 1: Search all pages
    filters = []
    if sgd: filters.append("우수판매자")
    if fdl: filters.append("빠른배송")
    print(f"검색: '{keyword}' (필터: {', '.join(filters) if filters else '없음'})")
    result = search_items(keyword, page=1, category=args.cg, sgd=sgd, fdl=fdl)
    if not result:
        print("검색 실패", file=sys.stderr)
        sys.exit(1)

    domeggook = result.get("domeggook", result)
    header = domeggook.get("header", {})
    total_items = int(header.get("numberOfItems", 0))
    total_pages = int(header.get("numberOfPages", 1))
    print(f"  → {total_items}건, {total_pages}페이지")

    if total_items == 0:
        print("검색 결과 없음")
        sys.exit(0)

    # Collect item numbers from all pages
    all_item_nos = []

    def collect_from_page(data):
        items = data.get("list", {}).get("item", [])
        if isinstance(items, dict):
            items = [items]
        for item in items:
            no = item.get("no", "")
            if no:
                all_item_nos.append(str(no))

    collect_from_page(domeggook)

    for pg in range(2, total_pages + 1):
        time.sleep(API_DELAY)
        result = search_items(keyword, page=pg, category=args.cg, sgd=sgd, fdl=fdl)
        if result:
            collect_from_page(result.get("domeggook", result))

    print(f"  상품번호 {len(all_item_nos)}개 수집")

    # Step 2: Fetch detail for each item
    print(f"\n상세정보 조회 중...")
    items = []
    for i, item_no in enumerate(all_item_nos, 1):
        print(f"  [{i}/{len(all_item_nos)}] {item_no}", end="")
        data = get_item_detail(item_no)
        if data:
            items.append(extract_item(data, item_no))
            print(f" ✓")
        else:
            print(f" ✗")
        time.sleep(API_DELAY)

    # Step 3: Save JSON
    output = {
        "keyword": keyword,
        "category_filter": args.cg or None,
        "collected_at": datetime.now().isoformat(),
        "total_items": len(items),
        "items": items,
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\n완료! {len(items)}건 저장: {output_path}")


if __name__ == "__main__":
    main()
