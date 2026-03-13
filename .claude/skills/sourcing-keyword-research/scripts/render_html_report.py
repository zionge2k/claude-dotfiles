#!/usr/bin/env python3
"""Render single item sourcing JSON data as HTML table report.

Usage:
    python3 render_html_report.py input.json
    python3 render_html_report.py input.json -o custom_output.html
"""
import argparse
import html
import json
import sys
from pathlib import Path

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{keyword} — 단품 소싱 리포트</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; padding: 20px; }}
  .header {{ background: #fff; padding: 20px 24px; border-radius: 8px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
  .header h1 {{ font-size: 20px; margin-bottom: 8px; }}
  .header .meta {{ color: #666; font-size: 13px; }}
  .controls {{ background: #fff; padding: 16px 24px; border-radius: 8px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; gap: 16px; align-items: center; flex-wrap: wrap; }}
  .controls label {{ font-size: 13px; color: #555; }}
  .controls select {{ padding: 6px 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 13px; }}
  .count {{ font-size: 13px; color: #888; margin-left: auto; }}
  .table-wrap {{ background: #fff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); overflow-x: auto; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  th {{ background: #f8f9fa; padding: 10px 12px; text-align: left; border-bottom: 2px solid #e0e0e0; white-space: nowrap; cursor: pointer; user-select: none; position: sticky; top: 0; z-index: 1; }}
  th:hover {{ background: #e9ecef; }}
  th .sort-arrow {{ margin-left: 4px; color: #aaa; }}
  th .sort-arrow.active {{ color: #333; }}
  td {{ padding: 8px 12px; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }}
  tr:hover {{ background: #f8f9fa; }}
  .thumb-cell img.thumb-sm {{ width: 80px; height: 80px; object-fit: cover; border-radius: 4px; cursor: pointer; }}
  #thumbPopup {{ display: none; position: fixed; z-index: 9999; max-width: 400px; max-height: 400px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); background: #fff; padding: 4px; pointer-events: none; }}
  #thumbPopup img {{ width: auto; height: auto; max-width: 392px; max-height: 392px; border-radius: 4px; }}
  .price {{ font-weight: 600; }}
  .badge {{ display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 11px; font-weight: 500; }}
  .badge-good {{ background: #d4edda; color: #155724; }}
  .badge-fast {{ background: #cce5ff; color: #004085; }}
  a.link {{ color: #0066cc; text-decoration: none; font-size: 12px; }}
  a.link:hover {{ text-decoration: underline; }}
  .title-cell {{ max-width: 300px; }}
  .cat-cell {{ max-width: 200px; color: #666; font-size: 12px; }}
</style>
</head>
<body>

<div class="header">
  <h1>"{keyword}" 단품 소싱 리포트</h1>
  <div class="meta">수집일: {collected_at} | 전체: {total_items}건{category_info}</div>
</div>

<div class="controls">
  <label>카테고리:
    <select id="catFilter">
      <option value="">전체</option>
    </select>
  </label>
  <label>우수판매자:
    <select id="goodFilter">
      <option value="">전체</option>
      <option value="true">우수만</option>
    </select>
  </label>
  <label>빠른배송:
    <select id="fastFilter">
      <option value="">전체</option>
      <option value="true">빠른배송만</option>
    </select>
  </label>
  <span class="count" id="resultCount"></span>
</div>

<div id="thumbPopup"><img id="thumbPopupImg" src="" alt=""></div>

<div class="table-wrap">
<table id="dataTable">
<thead>
<tr>
  <th>썸네일</th>
  <th data-sort="title">상품명 <span class="sort-arrow">⇅</span></th>
  <th>카테고리</th>
  <th data-sort="price_dome">도매꾹가 <span class="sort-arrow">⇅</span></th>
  <th data-sort="price_supply">도매매가 <span class="sort-arrow">⇅</span></th>
  <th>배송비</th>
  <th data-sort="seller_id">판매자 <span class="sort-arrow">⇅</span></th>
  <th data-sort="seller_score_avg">만족도 <span class="sort-arrow">⇅</span></th>
  <th data-sort="seller_score_cnt">판매자후기 <span class="sort-arrow">⇅</span></th>
  <th data-sort="moq">MOQ <span class="sort-arrow">⇅</span></th>
  <th>빠른배송</th>
</tr>
</thead>
<tbody id="tableBody">
</tbody>
</table>
</div>

<script>
const DATA = {json_data};

let sortKey = null;
let sortAsc = true;

function esc(s) {{
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}}

function formatPrice(n) {{
  if (n === 0 || n === "") return "-";
  return Number(n).toLocaleString();
}}

function createCell(tr, text, className) {{
  const td = document.createElement('td');
  td.textContent = text;
  if (className) td.className = className;
  tr.appendChild(td);
  return td;
}}

function renderRow(item) {{
  const tr = document.createElement('tr');
  tr.dataset.cat = item.category;
  tr.dataset.good = item.seller_good;
  tr.dataset.fast = item.fast_deli;

  // Thumbnail
  const tdThumb = document.createElement('td');
  if (item.thumbnail) {{
    const imgSm = document.createElement('img');
    imgSm.className = 'thumb-sm';
    imgSm.src = item.thumbnail;
    imgSm.alt = '';
    imgSm.loading = 'lazy';
    imgSm.dataset.fullSrc = item.thumbnail;
    tdThumb.className = 'thumb-cell';
    tdThumb.appendChild(imgSm);
  }} else {{
    tdThumb.textContent = '-';
  }}
  tr.appendChild(tdThumb);

  // Title with link to cheaper price
  const tdTitle = document.createElement('td');
  tdTitle.className = 'title-cell';
  const titleLink = document.createElement('a');
  titleLink.className = 'link';
  titleLink.target = '_blank';
  titleLink.rel = 'noopener';
  titleLink.textContent = item.title;
  const domePrice = item.price_dome || Infinity;
  const supplyPrice = item.price_supply || Infinity;
  titleLink.href = (supplyPrice < domePrice) ? item.url_domeme : item.url_dome;
  tdTitle.appendChild(titleLink);
  tr.appendChild(tdTitle);
  // Category
  createCell(tr, item.category, 'cat-cell');
  // Prices
  createCell(tr, formatPrice(item.price_dome), 'price');
  createCell(tr, formatPrice(item.price_supply), 'price');
  createCell(tr, formatPrice(item.deli_fee), '');

  // Seller
  const tdSeller = document.createElement('td');
  tdSeller.textContent = item.seller_id + ' ';
  if (item.seller_good) {{
    const badge = document.createElement('span');
    badge.className = 'badge badge-good';
    badge.textContent = '우수';
    tdSeller.appendChild(badge);
  }}
  tr.appendChild(tdSeller);

  // Score
  const avgVal = item.seller_score_avg ? String(item.seller_score_avg).replace(/%/g, '') + '%' : '-';
  createCell(tr, avgVal, '');
  createCell(tr, item.seller_score_cnt || '-', '');
  // MOQ
  createCell(tr, String(item.moq), '');

  // Fast delivery
  const tdFast = document.createElement('td');
  if (item.fast_deli) {{
    const badge = document.createElement('span');
    badge.className = 'badge badge-fast';
    badge.textContent = '빠른배송';
    tdFast.appendChild(badge);
  }}
  tr.appendChild(tdFast);


  return tr;
}}

function getCategories() {{
  const cats = new Set();
  DATA.forEach(item => {{ if (item.category) cats.add(item.category); }});
  return [...cats].sort();
}}

function populateCategoryFilter() {{
  const select = document.getElementById('catFilter');
  getCategories().forEach(cat => {{
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    select.appendChild(opt);
  }});
}}

function applyFilters() {{
  const catVal = document.getElementById('catFilter').value;
  const goodVal = document.getElementById('goodFilter').value;
  const fastVal = document.getElementById('fastFilter').value;

  let filtered = DATA.filter(item => {{
    if (catVal && item.category !== catVal) return false;
    if (goodVal && String(item.seller_good) !== goodVal) return false;
    if (fastVal && String(item.fast_deli) !== fastVal) return false;
    return true;
  }});

  if (sortKey) {{
    filtered.sort((a, b) => {{
      let va = a[sortKey], vb = b[sortKey];
      if (typeof va === 'number' && typeof vb === 'number') {{
        return sortAsc ? va - vb : vb - va;
      }}
      va = String(va || '');
      vb = String(vb || '');
      return sortAsc ? va.localeCompare(vb, 'ko') : vb.localeCompare(va, 'ko');
    }});
  }}

  const tbody = document.getElementById('tableBody');
  tbody.replaceChildren();
  filtered.forEach(item => tbody.appendChild(renderRow(item)));
  document.getElementById('resultCount').textContent = filtered.length + ' / ' + DATA.length + '건';
}}

function setupSorting() {{
  document.querySelectorAll('th[data-sort]').forEach(th => {{
    th.addEventListener('click', () => {{
      const key = th.dataset.sort;
      if (sortKey === key) {{
        sortAsc = !sortAsc;
      }} else {{
        sortKey = key;
        sortAsc = true;
      }}
      document.querySelectorAll('.sort-arrow').forEach(el => {{
        el.classList.remove('active');
        el.textContent = '⇅';
      }});
      const arrow = th.querySelector('.sort-arrow');
      arrow.classList.add('active');
      arrow.textContent = sortAsc ? '↑' : '↓';
      applyFilters();
    }});
  }});
}}

populateCategoryFilter();
setupSorting();
applyFilters();

document.getElementById('catFilter').addEventListener('change', applyFilters);
document.getElementById('goodFilter').addEventListener('change', applyFilters);
document.getElementById('fastFilter').addEventListener('change', applyFilters);

// Thumbnail popup on hover
const popup = document.getElementById('thumbPopup');
const popupImg = document.getElementById('thumbPopupImg');

document.getElementById('tableBody').addEventListener('mouseover', function(e) {{
  const img = e.target.closest('img.thumb-sm');
  if (!img) return;
  popupImg.src = img.dataset.fullSrc;
  popup.style.display = 'block';
}});

document.getElementById('tableBody').addEventListener('mousemove', function(e) {{
  if (popup.style.display !== 'block') return;
  const x = e.clientX + 16;
  const y = e.clientY - 200;
  const clampedY = Math.max(8, y);
  popup.style.left = x + 'px';
  popup.style.top = clampedY + 'px';
}});

document.getElementById('tableBody').addEventListener('mouseout', function(e) {{
  const img = e.target.closest('img.thumb-sm');
  if (!img) return;
  popup.style.display = 'none';
}});
</script>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Render sourcing HTML report from JSON")
    parser.add_argument("input", help="Input JSON file")
    parser.add_argument("-o", "--output", help="Output HTML file path")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    keyword = html.escape(data.get("keyword", ""))
    collected_at = html.escape(data.get("collected_at", "")[:10])
    total_items = data.get("total_items", 0)
    items = data.get("items", [])
    cat_filter = data.get("category_filter")
    category_info = f" | 카테고리 필터: {html.escape(cat_filter)}" if cat_filter else ""

    output_path = args.output or str(input_path.with_suffix(".html"))

    html_content = HTML_TEMPLATE.format(
        keyword=keyword,
        collected_at=collected_at,
        total_items=total_items,
        category_info=category_info,
        json_data=json.dumps(items, ensure_ascii=False),
    )

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"리포트 생성: {output_path} ({total_items}건)")


if __name__ == "__main__":
    main()
