---
name: obsidian-summarize-youtube
description: |
  Summarize a YouTube video transcript or URL and save as an Obsidian document. First argument selects language (kr|en, default: en).
argument-hint: "[kr|en] [transcript or YouTube URL]"
disable-model-invocation: true
---

# article summarize - $ARGUMENTS

제공되는 YouTube URL 또는 트랜스크립트를 번역/정리해서 obsidian 문서를 생성합니다.

## 언어 옵션 처리

```bash
# 첫 번째 인자로 언어 옵션 확인 (기본값: en)
LANG_OPTION="en"
CLEANED_ARGUMENTS="$ARGUMENTS"

# 첫 번째 단어가 언어 옵션인지 확인
FIRST_WORD=$(echo "$ARGUMENTS" | awk '{print $1}')
REST_ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/^[^ ]* *//')

if [[ "$FIRST_WORD" == "kr" ]] || [[ "$FIRST_WORD" == "ko" ]]; then
    LANG_OPTION="kr"
    CLEANED_ARGUMENTS="$REST_ARGUMENTS"
elif [[ "$FIRST_WORD" == "en" ]]; then
    LANG_OPTION="en"
    CLEANED_ARGUMENTS="$REST_ARGUMENTS"
else
    # 첫 번째 단어가 언어 옵션이 아니면 전체를 내용으로 처리 (기본 영어)
    LANG_OPTION="en"
    CLEANED_ARGUMENTS="$ARGUMENTS"
fi

echo "언어 옵션: $LANG_OPTION"
echo "처리할 내용: $CLEANED_ARGUMENTS"
```

먼저 입력 데이터 타입을 확인하겠습니다:

```bash
# YouTube URL 패턴 확인
if [[ "$CLEANED_ARGUMENTS" == *"youtube.com/watch?v="* ]] || [[ "$CLEANED_ARGUMENTS" == *"youtu.be/"* ]]; then
    echo "YouTube URL이 감지되었습니다."

    # 1단계: youtube-transcript-api로 트랜스크립트 다운로드
    # video ID 추출 후 언어 옵션에 따라 다운로드
    if [ "$LANG_OPTION" = "kr" ]; then
        echo "한글 트랜스크립트로 다운로드 시도 (실패 시 영어 fallback)"
    else
        echo "영어 트랜스크립트로 다운로드 시도 (실패 시 한글 fallback)"
    fi

    # Python으로 트랜스크립트 다운로드 (uv run 사용)
    uv run --with youtube-transcript-api python3 -c "
from youtube_transcript_api import YouTubeTranscriptApi
import re, sys
url = '$CLEANED_ARGUMENTS'
m = re.search(r'(?:v=|youtu\.be/)([^&?]+)', url)
if not m: sys.exit('video ID not found')
video_id = m.group(1)
ytt_api = YouTubeTranscriptApi()
langs = ['ko', 'en'] if '$LANG_OPTION' == 'kr' else ['en', 'ko']
for lang in langs:
    try:
        t = ytt_api.fetch(video_id, languages=[lang])
        print(' '.join([s.text for s in t.snippets]))
        sys.exit(0)
    except Exception: continue
t = ytt_api.fetch(video_id)
print(' '.join([s.text for s in t.snippets]))
"

    # 2단계: Playwright MCP로 메타데이터 추출
    # YouTube 페이지를 방문하여 영상 제목과 채널명을 추출한다.
    # browser_navigate → browser_snapshot으로 제목(h1), 채널명 확인

else
    echo "트랜스크립트 데이터로 처리합니다."
    TRANSCRIPT="$CLEANED_ARGUMENTS"
fi
```

## 작업 프로세스

1. **입력 데이터 분석 및 처리**
   - 첫 번째 인자로 언어 옵션 파싱: `kr`/`ko`/`en` 중 하나, 없으면 영어 우선 (기본값)
   - 첫 번째 단어가 언어 옵션이면 제거하고 나머지를 실제 내용으로 처리
   - 정제된 내용이 YouTube URL인지 확인 (youtube.com/watch?v=, youtu.be/ 패턴)
   - URL인 경우:
     - `uv run --with youtube-transcript-api`로 트랜스크립트 다운로드
     - 언어 옵션에 따라 한글 우선 또는 영어 우선으로 시도, 실패 시 대체 언어로 fallback
     - **Playwright MCP**로 YouTube 페이지 방문하여 메타데이터(제목, 채널명) 추출
   - 트랜스크립트인 경우: 기존 방식대로 직접 처리

2. **메타데이터 자동 생성** (URL인 경우)
   - id: 동영상 제목
   - aliases: 동영상 제목의 한국어 번역 (번역 필요한 경우)
   - author: 채널명 (소문자, 공백은 '-'로 변경)
   - created_at: 현재 obsidian 파일 생성 시점
   - source: 원본 YouTube URL

3. **번역 및 요약**
   - 아래 규칙(`## 문서 번역 및 요약 규칙`)에 따라 내용을 정리해서 yaml frontmatter를 포함한 obsidian file로 저장
   - **저장 경로**: `~/Documents/zion-vault/003-RESOURCES/` (반드시 이 경로에 저장)
   - **이미지 저장 경로**: `~/Documents/zion-vault/900-ATTACHMENTS/` (반드시 이 경로에 저장)
   - **이미지 네이밍 규칙**:
     - 문서 제목에서 kebab-case slug 생성 (핵심 단어 2-4개, 예: `clean-architecture-spring`, `tdd-patterns`)
     - 이미지 1개: `900-ATTACHMENTS/{slug}.{ext}` (폴더 생성 불필요)
     - 이미지 2개 이상: `900-ATTACHMENTS/{slug}/` 폴더 생성 후 그 안에 저장
     - 문서 내 참조: `../900-ATTACHMENTS/{slug}.{ext}` 또는 `../900-ATTACHMENTS/{slug}/파일명.{ext}`

4. **태그 부여**
   - hierarchical tagging 규칙은 `~/.claude/skills/obsidian-add-tag/SKILL.md` 에 정의된 규칙을 준수

5. **후처리 (문서 저장 후 자동 실행)**
   - 저장된 파일 경로를 기반으로 다음 명령어를 순차 실행:
     ```bash
     # 자동 태깅 (vis가 문서 내용을 분석하여 hierarchical tag 부여)
     vis tag "저장된_파일경로.md"

     # 관련 문서 연결 (vault 내 유사 문서를 찾아 Related 섹션 추가)
     vis add-related-docs "저장된_파일경로.md"
     ```
   - vis 명령어 실행 결과를 사용자에게 간략히 보고
   - vis가 설치되어 있지 않거나 에러 발생 시 건너뛰고 안내

## yaml frontmatter 예시

### YouTube URL인 경우 자동 생성되는 frontmatter:

```yaml
id: How to Implement Clean Architecture in Spring Boot
aliases: Spring Boot에서 Clean Architecture 구현 방법
tags:
  - architecture/clean-architecture/spring-implementation
  - architecture/hexagonal/ports-adapters
  - frameworks/spring-boot/architecture
  - development/practices/clean-code
author: coding-with-john
created_at: 2025-09-15 16:30
related: []
source: https://www.youtube.com/watch?v=lqQ_NL4y5Qg
```

### 트랜스크립트인 경우 수동 입력 필요한 frontmatter:

```yaml
id: 10 Essential Software Design Patterns used in Java Core Libraries
aliases: Java 코어 라이브러리에서 사용되는 10가지 필수 소프트웨어 디자인 패턴
tags:
  - patterns/design-patterns/java-implementation
  - patterns/creational/factory-singleton-builder
  - patterns/structural/adapter-facade-proxy
  - patterns/behavioral/observer-strategy-template
  - java/core-libraries/design-patterns
  - frameworks/java/standard-library
  - development/practices/object-oriented-design
  - architecture/patterns/gof-patterns
author: ali-zeynalli
created_at: 2025-09-04 11:39
related: []
source: https://azeynalli1990.medium.com/10-essential-software-design-patterns-used-in-java-core-libraries-bb8156ae279b
```

### Frontmatter 필드 설명:

- **id**: YouTube 제목 (자동 추출) 또는 문서에서 발견한 제목
- **aliases**: YouTube 제목의 한국어 번역 (번역 필요 시) 또는 문서 제목의 한국어 번역
- **author**: YouTube 채널명 (자동 추출, 소문자, 공백은 '-'로 변경) 또는 문서 작성자
- **created_at**: obsidian 파일 생성 시점 (자동 생성)
- **source**: YouTube URL (자동 추출) 또는 문서 URL

## 문서 번역 및 요약 규칙

```
Target Audience:
- Obtained a Computer Science degree and a master's degree in Korea
- Has worked as a software developer for over 25 years, developing and maintaining various services and products
- Cannot quickly read or watch content in English
- Interested in sustainable software system development, OOP, developer capability enhancement, Java, TDD, Design Patterns, Refactoring, DDD, Clean Code, Architecture (MSA, Modulith, Layered, Hexagonal, vertical slicing), Code Review, Agile (Lean) Development, Spring Boot, building development organizations and improving development culture, developer growth, and coaching
- Enjoys studying and organizing related topics for use in work and lectures

Translation Guidelines:
- Translate the input text to Korean
- For technical terms and programming-related concepts, include the original English term in parentheses when first mentioned
- Include as many original English terms as possible
- Prioritize literal translation over free translation, but use natural Korean expressions
- Use technical terminology and include code examples or diagrams when necessary
- Explicitly mark any uncertain parts

Summarization Structure:
1. Highlights/Summary: Summarize the entire content in 2-3 paragraphs
2. Detailed Summary: Divide the content into sections of about 5 minutes each, and summarize each section in 2-3 detailed paragraphs
3. Conclusion and Personal Views: Summarize the entire content in 5-10 statements and provide insights on why this information is important

Precautions:
- Explicitly mark any uncertainties in the translation and summarization process
- Use accurate and professional terminology as much as possible
- Balance the content of each section to avoid being too short or too long
- Include actual code examples or pseudocode to make explanations more concrete
- Explain complex concepts using analogies or examples for easier understanding
- Clearly state when you don't know certain information
- Self-verify the final information before responding
- Include all example codes in the document without omission

When you have completed the translation and summarization, present your work in the following artifact style format:

<translation_and_summary>
<highlights>
[Insert 2-3 paragraphs summarizing the entire content]
</highlights>

<detailed_summary>
[Insert detailed summary divided into sections, with 2-3 paragraphs for each section]
</detailed_summary>

<conclusion_and_views>
[Insert 5-10 summary statements and insights on the importance of the information]
</conclusion_and_views>
</translation_and_summary>

Remember to adhere to all the guidelines and precautions mentioned above throughout your translation and summarization
process.
```
