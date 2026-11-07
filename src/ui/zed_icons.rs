use std::{borrow::Cow, path::PathBuf};

use gpui_kit::{AssetSource, Result, SharedString};
use gpui_kit::component::Icon;

pub struct Assets {
    root: PathBuf,
}

impl Assets {
    pub fn new() -> Self {
        let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("resources/zed-icons");
        if !root.join("menu.svg").is_file() {
            eprintln!("zed icons missing: run tools/fetch-zed-icons.ps1");
        }
        Self { root }
    }
}

impl AssetSource for Assets {
    fn load(&self, path: &str) -> Result<Option<Cow<'static, [u8]>>> {
        if let Some(name) = path.strip_prefix("zed-icons/") {
            if name.contains(['/', '\\']) || !name.ends_with(".svg") {
                return Ok(None);
            }
            return match std::fs::read(self.root.join(name)) {
                Ok(bytes) => Ok(Some(Cow::Owned(bytes))),
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(None),
                Err(error) => Err(error.into()),
            };
        }
        if let Some(relative) = path.strip_prefix("res/") {
            // Icon theme files: any `.svg` below resources/, plain names only (no `..`, no drive or root parts).
            let plain = std::path::Path::new(relative).components().all(|c| matches!(c, std::path::Component::Normal(_)));
            if !plain || !relative.ends_with(".svg") {
                return Ok(None);
            }
            return match std::fs::read(self.root.parent().unwrap_or(&self.root).join(relative)) {
                Ok(bytes) => Ok(Some(Cow::Owned(bytes))),
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(None),
                Err(error) => Err(error.into()),
            };
        }
        gpui_kit::assets::Assets.load(path)
    }

    fn list(&self, path: &str) -> Result<Vec<SharedString>> {
        if path.starts_with("zed-icons/") {
            return match std::fs::read_dir(&self.root) {
                Ok(entries) => entries.map(|entry| {
                    let name = entry?.file_name();
                    Ok(format!("zed-icons/{}", name.to_string_lossy()).into())
                }).collect(),
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(Vec::new()),
                Err(error) => Err(error.into()),
            };
        }
        gpui_kit::assets::Assets.list(path)
    }
}

pub fn icon(name: &str) -> Icon {
    Icon::default().path(format!("zed-icons/{name}.svg"))
}

#[cfg(test)]
mod tests {
    use super::Assets;
    use gpui_kit::AssetSource;

    #[test]
    fn missing_zed_icons_are_empty_without_panic() {
        let assets = Assets { root: std::env::temp_dir().join(format!("absent-zed-icons-{}", std::process::id())) };
        assert!(!assets.root.exists());
        assert!(assets.load("zed-icons/menu.svg").unwrap().is_none());
        assert!(assets.list("zed-icons/").unwrap().is_empty());
        assert!(assets.load("zed-icons/../LICENSE-GPL.svg").unwrap().is_none());
        assert!(assets.load("icons/close.svg").unwrap().is_some());
        assert!(assets.load("res/zed-icons/file_icons/rust.svg").unwrap().is_none());
        for escape in ["res/../Cargo.toml", "res/zed-icons/../../Cargo.svg", "res//etc/x.svg", "res/C:/x.svg"] {
            assert!(assets.load(escape).unwrap().is_none(), "{escape}");
        }
    }

    #[test]
    fn k20_res_prefix_serves_resources_svg_only() {
        let assets = Assets::new();
        if assets.root.join("file_icons/rust.svg").is_file() {
            assert!(assets.load("res/zed-icons/file_icons/rust.svg").unwrap().is_some());
        }
        assert!(assets.load("res/fonts/lilex/OFL.txt").unwrap().is_none());
    }
}
