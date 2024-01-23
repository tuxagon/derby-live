use log::info;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

fn get_server_url() -> String {
    #[cfg(feature = "production")]
    {
        "https://derby-live.fly.dev".to_string()
    }
    #[cfg(not(feature = "production"))]
    {
        "http://localhost:4000".to_string()
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    pub api_key: Option<String>,
    pub event_key: Option<String>,
    pub database_path: Option<PathBuf>,
    pub server_url: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        let url = get_server_url();

        Self {
            api_key: Default::default(),
            event_key: Default::default(),
            database_path: Default::default(),
            server_url: url,
        }
    }
}

impl AppSettings {
    pub fn load() -> std::io::Result<Self> {
        let cwd = std::env::current_dir().expect("Failed to get current directory");
        info!(target: "settings::AppSettings::init", "cwd: {:?}", cwd);
        let file_contents = std::fs::read_to_string(cwd.join("settings.json"));
        match file_contents {
            Ok(contents) => {
                info!(target: "settings::AppSettings::init", "contents: {:?}", contents);
                info!(target: "settings::AppSettings::init", "parsed contents: {:?}", serde_json::from_str::<AppSettings>(&contents));
                let mut app_settings: AppSettings =
                    serde_json::from_str(&contents).unwrap_or_else(|_| AppSettings::default());
                info!(target: "settings::AppSettings::init", "app_settings: {:?}", app_settings);

                app_settings.update_server_url(get_server_url());
                Ok(app_settings)
            }
            Err(_) => {
                info!(target: "setup", "no settings.json found");
                Err(std::io::Error::new(
                    std::io::ErrorKind::NotFound,
                    "No settings.json found",
                ))?
            }
        }
    }

    pub async fn write(app_settings: AppSettings) -> Result<(), tauri::Error> {
        let cloned_settings = app_settings.clone();

        info!(target: "settings::AppSettings::write", "settings: {:?}", cloned_settings);

        tauri::async_runtime::spawn(async move {
            let cwd = std::env::current_dir();
            let file_path = cwd.unwrap().join("settings.json");
            let file_contents = serde_json::to_string_pretty(&cloned_settings).unwrap();
            std::fs::write(file_path, file_contents).unwrap();
        })
        .await?;

        Ok(())
    }

    pub fn current_database_path(&self) -> String {
        self.database_path
            .as_ref()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_default()
    }

    pub fn update_database_path_if_exists<P: AsRef<Path>>(&mut self, path: P) {
        if path.as_ref().exists() {
            self.database_path = Some(path.as_ref().to_path_buf());
        }
    }

    pub fn update_server_url(&mut self, url: String) {
        self.server_url = url;
    }
}
