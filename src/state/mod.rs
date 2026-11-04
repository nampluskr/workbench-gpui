//! `state.json` (v0.2 Phase 3, SPEC R-28, DECISIONS D-10·D-11, D-10 이후 변경 D-035).
//!
//! 쓰는 범위(D-10): `version`, `windows[0].folders[]`(`id`, `path`, `added_at`), `windows[0].active_folder_id`,
//! `windows[0].sidebar.width`. 그 밖의 키는 읽을 때 무시하고 쓸 때 보존한다(A-20 아래 목록).
//!
//! 쓰기·읽기 규칙은 01-zed A-24.1~A-24.7 이다(D-035 ③).
//! - A-24.1 `state.json.tmp` 에 전체를 쓰고 `sync_all` 한 뒤 `ReplaceFileW`/`MoveFileExW` 로 바꾼다(`win.rs`).
//! - A-24.4 교체 실패 때 50ms 간격으로 3번 다시 시도하고, 그래도 실패하면 `.tmp` 를 두고 `Could not save the window state.`.
//! - A-24.5 `state.json` 이 없거나 깨졌고 `.tmp` 가 올바르면 `.tmp` 를 쓴다. 둘 다 안 되면 빈 상태.
//! - A-24.6 깨진 `state.json` 은 `state.json.bad-YYYYMMDD-HHMMSS`(UTC, `-2`, `-3`…)로 옮기고 최근 3개만 남긴다.
//!   알림 문구는 `Could not read the window state.`(우리 문구, D-035 ②).
//! - A-24.7 `version` 이 앱(1)보다 크면 읽기만 하고 쓰지 않는다.
//! A-24.2(500ms 묶어 쓰기)·A-24.3(종료 직전 쓰기)은 화면 쪽(`ui::folders`)이 부른다.

pub mod path;
pub mod time;
pub mod win;

use std::path::{Path, PathBuf};

use serde_json::{Map, Value, json};

/// A-22.1 파일 형식 버전.
pub const STATE_VERSION: u64 = 1;
/// 읽기 오류 알림(우리 문구, D-035 ②).
pub const ERR_READ: &str = "Could not read the window state.";
/// 저장 실패 알림(A-24.4 원문 문구).
pub const ERR_SAVE: &str = "Could not save the window state.";

const FILE: &str = "state.json";
const TMP: &str = "state.json.tmp";
const BAD_PREFIX: &str = "state.json.bad-";
/// A-24.6 남기는 깨진 파일 수.
const BAD_KEEP: usize = 3;
/// A-24.4 다시 시도 횟수(간격은 metrics::timing).
use crate::ui::metrics::timing::STATE_RETRY_DELAY as RETRY_DELAY;
const RETRIES: usize = 3;

/// 등록 폴더 하나(A-22.3~A-22.5).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Folder {
    pub id: String,
    pub path: String,
    pub added_at: String,
}

/// 메모리 상태와, 보존할 원래 JSON.
#[derive(Clone, Debug, Default)]
pub struct State {
    pub folders: Vec<Folder>,
    pub active: Option<String>,
    pub sidebar_width: Option<f64>,
    /// 읽은 파일 전체(알 수 없는 키 보존용). 없으면 빈 객체.
    raw: Map<String, Value>,
    /// A-24.7 버전이 앱보다 커서 쓰지 않는다.
    pub read_only: bool,
}

/// 읽기 결과.
#[derive(Debug)]
pub struct Loaded {
    pub state: State,
    /// 어디서 읽었나: `state`, `tmp`, `none`(파일 없음), `empty`(둘 다 못 읽음).
    pub source: &'static str,
    /// 알림 문구(깨진 파일이 있었으면 `ERR_READ`).
    pub notice: Option<&'static str>,
    /// 깨진 파일을 옮긴 경로(A-24.6).
    pub bad_moved_to: Option<PathBuf>,
}

/// 저장 결과.
#[derive(Debug, PartialEq, Eq)]
pub enum Saved {
    Written,
    /// A-24.7: 버전이 커서 쓰지 않았다.
    SkippedReadOnly,
}

impl State {
    /// JSON 객체에서 읽는다. 형식이 맞지 않는 항목은 건너뛴다.
    fn from_object(raw: Map<String, Value>) -> Self {
        let version = raw.get("version").and_then(Value::as_u64).unwrap_or(STATE_VERSION);
        let window = raw
            .get("windows")
            .and_then(Value::as_array)
            .and_then(|w| w.first())
            .and_then(Value::as_object);
        let mut folders = Vec::new();
        if let Some(list) = window.and_then(|w| w.get("folders")).and_then(Value::as_array) {
            for f in list {
                let (Some(id), Some(p)) = (
                    f.get("id").and_then(Value::as_str),
                    f.get("path").and_then(Value::as_str),
                ) else {
                    continue;
                };
                let Some(p) = path::normalize(p) else {
                    continue;
                };
                folders.push(Folder {
                    id: id.to_string(),
                    path: p,
                    added_at: f
                        .get("added_at")
                        .and_then(Value::as_str)
                        .unwrap_or_default()
                        .to_string(),
                });
            }
        }
        // A-22.6: folders 에 없으면 첫 폴더, 폴더가 없으면 null.
        let active = window
            .and_then(|w| w.get("active_folder_id"))
            .and_then(Value::as_str)
            .filter(|id| folders.iter().any(|f| f.id == *id))
            .map(str::to_string)
            .or_else(|| folders.first().map(|f| f.id.clone()));
        let sidebar_width = window
            .and_then(|w| w.get("sidebar"))
            .and_then(|s| s.get("width"))
            .and_then(Value::as_f64);
        Self {
            folders,
            active,
            sidebar_width,
            raw,
            read_only: version > STATE_VERSION,
        }
    }

    /// 쓸 JSON. 읽은 원래 객체 위에 D-10 범위의 값만 덮어쓴다(알 수 없는 키 보존).
    pub fn to_value(&self) -> Value {
        let mut root = self.raw.clone();
        root.insert("version".into(), json!(STATE_VERSION));
        let mut windows: Vec<Value> = root
            .get("windows")
            .and_then(Value::as_array)
            .cloned()
            .unwrap_or_default();
        if windows.is_empty() || !windows[0].is_object() {
            if windows.is_empty() {
                windows.push(json!({}));
            } else {
                windows[0] = json!({});
            }
        }
        let window = windows[0].as_object_mut().expect("object");
        let old_folders: Vec<Value> = window
            .get("folders")
            .and_then(Value::as_array)
            .cloned()
            .unwrap_or_default();
        let folders: Vec<Value> = self
            .folders
            .iter()
            .map(|f| {
                let mut obj = old_folders
                    .iter()
                    .find(|o| o.get("id").and_then(Value::as_str) == Some(f.id.as_str()))
                    .and_then(Value::as_object)
                    .cloned()
                    .unwrap_or_default();
                obj.insert("id".into(), json!(f.id));
                obj.insert("path".into(), json!(f.path));
                obj.insert("added_at".into(), json!(f.added_at));
                Value::Object(obj)
            })
            .collect();
        window.insert("folders".into(), Value::Array(folders));
        window.insert(
            "active_folder_id".into(),
            self.active.as_ref().map_or(Value::Null, |a| json!(a)),
        );
        if let Some(width) = self.sidebar_width {
            let mut sidebar = window
                .get("sidebar")
                .and_then(Value::as_object)
                .cloned()
                .unwrap_or_default();
            sidebar.insert("width".into(), json!(width));
            window.insert("sidebar".into(), Value::Object(sidebar));
        }
        root.insert("windows".into(), Value::Array(windows));
        Value::Object(root)
    }
}

fn read_object(p: &Path) -> Result<Option<Map<String, Value>>, ()> {
    match std::fs::read(p) {
        Ok(bytes) => {
            let text = String::from_utf8(bytes).map_err(|_| ())?;
            match serde_json::from_str::<Value>(text.trim_start_matches('\u{feff}')) {
                Ok(Value::Object(obj)) => Ok(Some(obj)),
                _ => Err(()),
            }
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(_) => Err(()),
    }
}

/// A-24.6: 깨진 파일을 옮기고 최근 `BAD_KEEP` 개만 남긴다.
fn move_bad(dir: &Path) -> Option<PathBuf> {
    let src = dir.join(FILE);
    let base = format!("{BAD_PREFIX}{}", time::stamp_now());
    let mut target = dir.join(&base);
    let mut n = 2;
    while target.exists() {
        target = dir.join(format!("{base}-{n}"));
        n += 1;
    }
    std::fs::rename(&src, &target).ok()?;
    let mut bads: Vec<(std::time::SystemTime, PathBuf)> = std::fs::read_dir(dir)
        .ok()?
        .flatten()
        .filter(|e| e.file_name().to_string_lossy().starts_with(BAD_PREFIX))
        .filter_map(|e| Some((e.metadata().ok()?.modified().ok()?, e.path())))
        .collect();
    bads.sort_by(|a, b| b.0.cmp(&a.0).then_with(|| b.1.cmp(&a.1)));
    for (_, old) in bads.into_iter().skip(BAD_KEEP) {
        let _ = std::fs::remove_file(old);
    }
    Some(target)
}

/// 앱 데이터 폴더에서 읽는다(A-24.5·A-24.6·A-24.7).
pub fn load(dir: &Path) -> Loaded {
    let main = read_object(&dir.join(FILE));
    let broken = main.is_err();
    let (state, source) = match main {
        Ok(Some(obj)) => (State::from_object(obj), "state"),
        _ => match read_object(&dir.join(TMP)) {
            Ok(Some(obj)) => (State::from_object(obj), "tmp"),
            _ => (
                State::default(),
                if broken || dir.join(TMP).exists() { "empty" } else { "none" },
            ),
        },
    };
    let bad_moved_to = if broken { move_bad(dir) } else { None };
    Loaded {
        state,
        source,
        notice: broken.then_some(ERR_READ),
        bad_moved_to,
    }
}

/// 앱 데이터 폴더에 쓴다(A-24.1·A-24.4·A-24.7). 실패하면 `ERR_SAVE`.
pub fn save(dir: &Path, state: &State) -> Result<Saved, &'static str> {
    if state.read_only {
        return Ok(Saved::SkippedReadOnly);
    }
    let write = || -> std::io::Result<()> {
        std::fs::create_dir_all(dir)?;
        let tmp = dir.join(TMP);
        let text = serde_json::to_string_pretty(&state.to_value())
            .map_err(|e| std::io::Error::other(e.to_string()))?;
        let mut f = std::fs::File::create(&tmp)?;
        std::io::Write::write_all(&mut f, text.as_bytes())?;
        f.sync_all()?;
        drop(f);
        let target = dir.join(FILE);
        let mut last = win::replace_file(&tmp, &target);
        for _ in 0..RETRIES {
            if last.is_ok() {
                break;
            }
            std::thread::sleep(RETRY_DELAY);
            last = win::replace_file(&tmp, &target);
        }
        last
    };
    write().map(|_| Saved::Written).map_err(|_| ERR_SAVE)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir(tag: &str) -> PathBuf {
        let d = std::env::temp_dir().join(format!("wg-state-test-{tag}-{}", win::new_uuid()));
        std::fs::create_dir_all(&d).unwrap();
        d
    }

    fn folder(id: &str, p: &str) -> Folder {
        Folder {
            id: id.into(),
            path: p.into(),
            added_at: "2026-11-01T00:00:00Z".into(),
        }
    }

    #[test]
    fn roundtrip_and_unknown_keys() {
        let dir = temp_dir("rt");
        std::fs::write(
            dir.join(FILE),
            r#"{"version":1,"extra":{"k":1},"windows":[{"id":"w1","left_dock":{"open":true},
               "folders":[{"id":"a","path":"C:\\x","added_at":"t","note":"keep"}],
               "active_folder_id":"zzz","sidebar":{"width":320,"open":false}}],"recent":["C:\\y"]}"#,
        )
        .unwrap();
        let mut loaded = load(&dir);
        assert_eq!(loaded.source, "state");
        assert_eq!(loaded.state.active.as_deref(), Some("a")); // A-22.6 없는 id → 첫 폴더
        assert_eq!(loaded.state.sidebar_width, Some(320.0));
        loaded.state.folders.push(folder("b", "D:\\z"));
        loaded.state.active = Some("b".into());
        loaded.state.sidebar_width = Some(410.0);
        assert_eq!(save(&dir, &loaded.state), Ok(Saved::Written));
        let v: Value = serde_json::from_str(&std::fs::read_to_string(dir.join(FILE)).unwrap()).unwrap();
        assert_eq!(v["extra"]["k"], 1);
        assert_eq!(v["recent"][0], "C:\\y");
        assert_eq!(v["windows"][0]["id"], "w1");
        assert_eq!(v["windows"][0]["left_dock"]["open"], true);
        assert_eq!(v["windows"][0]["folders"][0]["note"], "keep");
        assert_eq!(v["windows"][0]["folders"][1]["id"], "b");
        assert_eq!(v["windows"][0]["active_folder_id"], "b");
        assert_eq!(v["windows"][0]["sidebar"]["width"], 410.0);
        assert_eq!(v["windows"][0]["sidebar"]["open"], false);
        assert!(!dir.join(TMP).exists());
    }

    #[test]
    fn broken_file_is_moved_and_tmp_recovers() {
        let dir = temp_dir("bad");
        std::fs::write(dir.join(FILE), "{ broken").unwrap();
        let loaded = load(&dir);
        assert_eq!(loaded.source, "empty");
        assert_eq!(loaded.notice, Some(ERR_READ));
        assert!(loaded.bad_moved_to.is_some());
        assert!(!dir.join(FILE).exists());

        std::fs::write(dir.join(FILE), "[]").unwrap();
        std::fs::write(
            dir.join(TMP),
            r#"{"version":1,"windows":[{"folders":[{"id":"t","path":"C:\\t","added_at":""}]}]}"#,
        )
        .unwrap();
        let loaded = load(&dir);
        assert_eq!(loaded.source, "tmp");
        assert_eq!(loaded.state.folders.len(), 1);
        assert_eq!(loaded.notice, Some(ERR_READ));
    }

    #[test]
    fn keeps_three_bad_files() {
        let dir = temp_dir("keep");
        for _ in 0..5 {
            std::fs::write(dir.join(FILE), "nope").unwrap();
            let _ = load(&dir);
        }
        let bads = std::fs::read_dir(&dir)
            .unwrap()
            .flatten()
            .filter(|e| e.file_name().to_string_lossy().starts_with(BAD_PREFIX))
            .count();
        assert_eq!(bads, BAD_KEEP);
    }

    #[test]
    fn newer_version_is_read_only() {
        let dir = temp_dir("ver");
        let text = r#"{"version":2,"windows":[{"folders":[]}]}"#;
        std::fs::write(dir.join(FILE), text).unwrap();
        let mut loaded = load(&dir);
        assert!(loaded.state.read_only);
        loaded.state.folders.push(folder("x", "C:\\x"));
        assert_eq!(save(&dir, &loaded.state), Ok(Saved::SkippedReadOnly));
        assert_eq!(std::fs::read_to_string(dir.join(FILE)).unwrap(), text);
    }

    #[test]
    fn missing_file_is_empty_without_notice() {
        let dir = temp_dir("none");
        let loaded = load(&dir);
        assert_eq!(loaded.source, "none");
        assert_eq!(loaded.notice, None);
        assert!(loaded.state.folders.is_empty());
    }
}
