[DONE] ORDER-01-R1 gpui

## 완료 기준
| 번호 | 기준 | 결과 | 근거 |
|---|---|---|---|
| 1 | 갈래 지침에 core ITEMS와 부딪치는 문장이 없다 | 충족 | 아래 "고친 문장" 8건. 경계 사례 10건(부딪치지 않음 판단)은 `specs/v0.5/cards/W-02.report.md` "찾았지만 부딪치지 않는다고 본 경계 사례". checker C-02가 판단 확인 |
| 2 | "core ITEMS 우선(core D-12)" 문장 | 충족 | `AGENTS.md` 레포 규칙 "**core ITEMS 우선** — workbench-core v0.5 `ITEMS.md`(I-1~I-23)가 이 레포 지침보다 우선한다. (출처: workbench-core v0.5 DECISIONS D-12)" |
| 3 | v0.5 SPEC·PLAN에 I-2·I-22 충돌 "미정" 없음 | 충족 | SPEC R-2·R-22 "이 요구가 루트 INTENT보다 우선한다(core D-12)". PLAN Phase 8 완료 조건에 "진단(I-22)… 빼지 않는다. 막히면 `[BLOCKED]`". DECISIONS 미결 사항에서 해당 줄 삭제 |
| 4 | 이 보고 파일 | 충족 | `specs/v0.5/reports/ORDER-01-R1.md` |

## 고친 문장
고치는 방식: 지우지 않고 "단, core v0.5 ITEMS I-n은 예외(core D-12)."를 붙였다(leader 결정). 지운 문장 없음.

| 파일 | 고치기 전 | 고친 뒤 | 대응 I-n |
|---|---|---|---|
| `INTENT.md` 변하지 않는 원칙 1 | Zed와 같아야 한다. 레이아웃·사용감·아이콘·테마를 Zed 기준으로 맞추고, 같은지는 명세와 대조해 확인한다. | + 단, core v0.5 ITEMS I-6·I-17·I-21은 예외(core D-12). | I-6·I-17·I-21 (ITEMS가 Zed와 다르게 정함) |
| `INTENT.md` 변하지 않는 원칙 3 | 쓰지 않는 기능의 아이콘·메뉴·옵션은 넣지 않는다. | + 단, core v0.5 ITEMS I-2·I-22는 예외(core D-12). | I-2·I-22 |
| `INTENT.md` 다루지 않는 것 3 | 프로젝트 전체 검색, 설정 UI 화면, 업데이트 확인, 오른쪽·하단 Dock. | + 단, core v0.5 ITEMS I-2·I-22는 예외(core D-12). | I-2·I-22 |
| `INTENT.md` 다루지 않는 것 4 | 화면을 추가하는 확장, 온라인 확장 목록. | + 단, core v0.5 ITEMS I-2는 예외(core D-12). | I-2 |
| `AGENTS.md` 레포 규칙 | (없음) | core ITEMS 우선 줄 추가 | I-1~I-23 |
| `AGENTS.md` 1장 핵심 원칙 | Zed 실측값은 요구사항이다. | + 단, core v0.5 ITEMS I-6은 예외(core D-12). | I-6 |
| `AGENTS.md` 3장 첫 줄 | 모든 크기·간격·색상·폰트·동작 타이밍은 `spec/zed-metrics.toml`의 항목 ID로 참조한다. 수치의 기준은 이 toml 하나다. | + 단, core v0.5 ITEMS I-6·I-14에 적힌 값은 예외(core D-12). | I-6·I-14 |
| `AGENTS.md` 3장 스펙에 없는 값 | 스펙에 없는 값이 필요하면 추정하지 말고 `leader`를 통해 `spec`에게 요청한다. | + 단, core v0.5 ITEMS가 갈래에게 Zed 확인을 맡긴 값(I-2·5·9·12·14·15·16·23)은 예외(core D-12). | I-2·I-5·I-9·I-12·I-14·I-15·I-16·I-23 |

`specs/v0.5/` 정리: INTENT 제외 범위·배경, DECISIONS 적용 표(D-12 행)·미결 사항, SPEC R-2·R-22, PLAN 대응 표(Phase 1·6·8)·Phase 8 완료 조건, PROGRESS W-02.

## 바꾼 파일
- `INTENT.md`, `AGENTS.md`, `specs/v0.5/{INTENT,DECISIONS,SPEC,PLAN,PROGRESS}.md`, `specs/v0.5/cards/{W-02,C-02}.md`·`.report.md`, 이 보고
- 커밋: 이 보고와 같은 커밋(`git log -1 -- specs/v0.5/reports/ORDER-01-R1.md`). push 없음

## 검토
- checker C-02: **PASS** (`specs/v0.5/cards/C-02.report.md`). 항목 1~4 충족, 경계 사례 판단 적정, 지적 없음.
- 참고(범위 밖, 고치지 않음): `README.md`의 v0.4 상태 설명이 낡았다(ITEMS와 충돌 아님).

## BLOCKED
없음
