//! 프로젝트 패널의 디스크 쪽 일 (v0.2 Phase 4, SPEC R-17·R-19~R-21). gpui 와 무관하다.
//!
//! - `list`: 폴더 읽기와 정렬(L-50 폴더 먼저, 대소문자 무시 자연 정렬).
//! - `names`: 인라인 입력칸 이름 검증·확정(P-019~P-022).
//! - `ops`: 만들기·이름 바꾸기·복사·이동·휴지통·영구 삭제, 붙여넣기 이름 고르기.
//! - `paths`: 경로 복사 문자열(I-548·I-549), 툴팁 경로(L-247).

pub mod list;
pub mod names;
pub mod ops;
pub mod paths;
pub mod tree;
