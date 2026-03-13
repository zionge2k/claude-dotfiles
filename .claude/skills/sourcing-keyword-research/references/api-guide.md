# 도매꾹 API Quick Reference

## Search API (getItemList v4.1)

```
https://domeggook.com/ssl/api/?ver=4.1&mode=getItemList&aid={API_KEY}&market=dome&om=json&kw={keyword}&sgd=true&fdl=true&mxq=1&sz=200&pg=1&so=rd
```

### Key Parameters
| Parameter | Value | Description |
|-----------|-------|-------------|
| `kw` | string | Search keyword |
| `sgd` | `true` | 우수판매자 only |
| `fdl` | `true` | 빠른배송 only |
| `mxq` | `1` | Max MOQ filter |
| `sz` | 1-200 | Results per page |
| `pg` | int | Page number |
| `so` | `rd` | Sort order (relevance) |
| `cg` | string | Category code (e.g., `01_07_07_00_00`) |

### Response
- `header.numberOfItems` — total results count
- `list.item[]` — array of items
  - `no` — item number
  - `title` — product name
  - `id` — seller ID
  - `unitQty` — MOQ
  - `price` — price

## Detail API (getItemView v4.5)

```
https://domeggook.com/ssl/api/?ver=4.5&mode=getItemView&aid={API_KEY}&no={item_no}&om=json
```

### Key Response Fields
- `basis.title` — product name
- `basis.keywords.kw` — product keywords
- `category.parents.elem[].name` — parent category names
- `category.current.name` — current category name
- `price.dome` — wholesale price
- `price.supply` — supply price
- `seller.id`, `seller.nick`, `seller.good` — seller info
- `deli.fastDeli` — fast delivery flag
- `qty.domeMoq` — MOQ
- `desc.license.usable` — image usage allowed

## collect_set_data.py Location

```
/Users/iseong/projects/domeggook-product-sourcing/collect_set_data.py
```

### Key Sections to Update
- `COMPONENTS` dict — component name → keyword list mapping
- `EXCLUDE_FILTERS` dict — component name → exclusion keyword list
- `output_path` in `main()` — output CSV filename
