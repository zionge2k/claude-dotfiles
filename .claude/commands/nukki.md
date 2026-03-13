---
argument-hint: "<image_path> [--target 1320] [--output ~/Desktop/]"
description: "상품 이미지에서 고품질 누끼(배경 제거 + AI 업스케일)를 생성"
---

# 누끼 생성 - $ARGUMENTS

상품 이미지에서 배경을 제거하고 AI 업스케일하여 고품질 누끼 PNG를 생성합니다.

## 스크립트 위치

`~/bin/nukki.py` (PEP 723 inline metadata, `uv run`으로 실행)

## 실행 프로세스

1. **인자 파싱**: `$ARGUMENTS`에서 이미지 경로와 옵션을 추출
   - 이미지 경로: 필수 (단일 파일 또는 glob 패턴)
   - `--target`: 타겟 해상도 (기본 1320px, 스마트스토어 대표이미지 권장)
   - `--output`: 출력 디렉토리 (기본: 입력 파일과 같은 위치)

2. **스크립트 실행**:
   ```bash
   uv run ~/bin/nukki.py <parsed_arguments>
   ```

3. **결과 확인**: 생성된 누끼 이미지를 Read 도구로 표시

## 사용 예시

```
/nukki ~/Downloads/product/detail_1.png
/nukki ~/Downloads/product/detail_1.png --target 1600
/nukki ~/Downloads/product/detail_1.png --output ~/Desktop/
/nukki ~/Downloads/product/*.png
```

## 파이프라인 상세

| 단계 | 도구 | 설명 |
|------|------|------|
| 배경 제거 | rembg (u2net) | RGBA 투명 배경 누끼 |
| AI 업스케일 | Real-ESRGAN x4plus | 동적 outscale (타겟 기준 자동 계산) |

- 원본 >= 타겟: 업스케일 skip
- outscale <= 4.0: 네이티브 4x (최상 품질)
- outscale > 4.0: 4x 후 Lanczos 보간

## 출력 파일명

`{원본이름}_nukki_{해상도}px.png`

예: `detail_1.png` → `detail_1_nukki_1320px.png`
