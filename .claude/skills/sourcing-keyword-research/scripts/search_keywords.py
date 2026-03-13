#!/usr/bin/env python3
"""도매꾹 API keyword research helper.

Usage:
    python3 search_keywords.py <keyword> [--detail <item_no>] [--size <n>]

Examples:
    python3 search_keywords.py "화장품 파우치"
    python3 search_keywords.py "화장품 파우치" --size 10
    python3 search_keywords.py --detail 59959573
"""
import json
import urllib.request
import urllib.parse
import sys
import argparse

import os

API_KEY = os.environ.get("DOMEGGOOK_API_KEY", "")
if not API_KEY:
    print("Error: DOMEGGOOK_API_KEY environment variable is not set", file=sys.stderr)
    sys.exit(1)
BASE_URL = "https://domeggook.com/ssl/api/"


def api_get(params):
    url = BASE_URL + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"[API ERROR] {e}", file=sys.stderr)
        return None


def search_items(keyword, size=20):
    """Search with standard filters: 우수판매자 + 빠른배송 + MOQ 1."""
    params = {
        "ver": "4.1",
        "mode": "getItemList",
        "aid": API_KEY,
        "market": "dome",
        "om": "json",
        "kw": keyword,
        "sgd": "true",
        "fdl": "true",
        "mxq": 1,
        "sz": size,
        "pg": 1,
        "so": "rd",
    }
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


def format_search_result(result):
    """Format search result for display."""
    domeggook = result.get("domeggook", result)
    header = domeggook.get("header", {})
    num_items = header.get("numberOfItems", 0)
    num_pages = header.get("numberOfPages", 0)

    output = {
        "totalItems": int(num_items),
        "totalPages": int(num_pages),
        "items": [],
    }

    items = domeggook.get("list", {}).get("item", [])
    if isinstance(items, dict):
        items = [items]

    for item in items:
        output["items"].append({
            "no": item.get("no", ""),
            "title": item.get("title", ""),
            "sellerId": item.get("id", ""),
            "unitQty": item.get("unitQty", ""),
            "price": item.get("price", ""),
        })

    return output


def format_detail_result(data):
    """Format detail result for display."""
    def safe_get(d, *keys, default=""):
        current = d
        for key in keys:
            if isinstance(current, dict):
                current = current.get(key, default)
            else:
                return default
        return current if current is not None else default

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
        "title": safe_get(data, "basis", "title", default=""),
        "category": cat_path,
        "price_dome": safe_get(data, "price", "dome", default=""),
        "price_supply": safe_get(data, "price", "supply", default=""),
        "seller_id": safe_get(data, "seller", "id", default=""),
        "seller_nick": safe_get(data, "seller", "nick", default=""),
        "seller_good": safe_get(data, "seller", "good", default=""),
        "keywords": keywords,
        "moq": safe_get(data, "qty", "domeMoq", default=""),
        "fast_deli": safe_get(data, "deli", "fastDeli", default=""),
    }


def main():
    parser = argparse.ArgumentParser(description="도매꾹 API keyword research")
    parser.add_argument("keyword", nargs="?", help="Search keyword")
    parser.add_argument("--detail", type=int, help="Item number for detail view")
    parser.add_argument("--size", type=int, default=20, help="Number of results (default: 20)")
    args = parser.parse_args()

    if args.detail:
        data = get_item_detail(args.detail)
        if data:
            print(json.dumps(format_detail_result(data), ensure_ascii=False, indent=2))
        else:
            print("Failed to fetch detail", file=sys.stderr)
            sys.exit(1)
    elif args.keyword:
        result = search_items(args.keyword, size=args.size)
        if result:
            print(json.dumps(format_search_result(result), ensure_ascii=False, indent=2))
        else:
            print("Failed to search", file=sys.stderr)
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
