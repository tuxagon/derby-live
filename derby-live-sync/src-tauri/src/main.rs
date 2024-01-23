// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

extern crate log;
extern crate serde;
extern crate tauri;

mod client_notify;
mod database;
mod logger;
mod synchronize;

use log::info;
use serde::{Deserialize, Serialize};
use std::{
    path::{Path, PathBuf},
    sync::{Arc, Mutex},
};
use synchronize::{SyncCreationError, SyncState, Synchronizer};
use tauri::Manager;

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
struct AppSettings {
    api_key: Option<String>,
    event_key: Option<String>,
    database_path: Option<PathBuf>,
    server_url: String,
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
    fn current_database_path(&self) -> String {
        self.database_path
            .as_ref()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_default()
    }

    fn update_database_path_if_exists<P: AsRef<Path>>(&mut self, path: P) {
        if path.as_ref().exists() {
            self.database_path = Some(path.as_ref().to_path_buf());
        }
    }

    fn update_server_url(&mut self, url: String) {
        self.server_url = url;
    }
}

struct AppState {
    app_settings: AppSettings,
    synchronizer: Option<Synchronizer>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            app_settings: Default::default(),
            synchronizer: Default::default(),
        }
    }
}

fn extract_app_settings(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> AppSettings {
    let state_locked = app_state.lock().unwrap();
    state_locked.app_settings.clone()
}

fn assign_database_path(app_state: Arc<Mutex<AppState>>, database_path: Option<PathBuf>) -> String {
    let mut state_locked = app_state.lock().unwrap();

    if let Some(path) = database_path {
        state_locked
            .app_settings
            .update_database_path_if_exists(path);
    } else {
        state_locked.app_settings.database_path = None;
    }

    state_locked.app_settings.current_database_path()
}

fn try_create_synchronizer(
    app_handle: tauri::AppHandle,
    app_settings: AppSettings,
) -> Result<Synchronizer, SyncCreationError> {
    let sync_state = SyncState::try_new(
        app_handle.clone(),
        app_settings.database_path,
        app_settings.api_key,
        app_settings.event_key,
        Some(app_settings.server_url),
    )?;

    Ok(Synchronizer::new(sync_state))
}

async fn write_settings(app_settings: AppSettings) -> Result<(), tauri::Error> {
    let cloned_settings = app_settings.clone();

    info!(target: "operation", "write_settings: {:?}", cloned_settings);

    tauri::async_runtime::spawn(async move {
        let cwd = std::env::current_dir();
        let file_path = cwd.unwrap().join("settings.json");
        let file_contents = serde_json::to_string_pretty(&cloned_settings).unwrap();
        std::fs::write(file_path, file_contents).unwrap();
    })
    .await?;

    Ok(())
}

#[tauri::command]
fn fetch_app_settings(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> AppSettings {
    let app_settings = extract_app_settings(app_state);
    info!(target: "command", "fetch_app_settings: {:?}", app_settings);
    app_settings
}

#[tauri::command]
fn fetch_database_path(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> String {
    let app_settings = extract_app_settings(app_state);
    info!(target: "command", "fetch_database_path: {:?}", app_settings);
    app_settings.current_database_path()
}

#[tauri::command]
async fn choose_database(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state = Arc::clone(&app_state);

    info!(target: "command", "choose_database");

    tauri::api::dialog::FileDialogBuilder::new().pick_file(move |file_path| {
        {
            let chosen_file_path = assign_database_path(Arc::clone(&state), file_path);

            client_notify::database_chosen(Arc::new(app_handle), chosen_file_path);
        }

        tauri::async_runtime::spawn(write_settings(state.lock().unwrap().app_settings.clone()));
    });

    Ok(())
}

#[tauri::command]
async fn save_settings(
    api_key: String,
    event_key: String,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state = Arc::clone(&app_state);

    info!(target: "command", "save_settings: api_key:{:?}, event_key:{:?}", api_key, event_key);

    {
        let mut state_locked = state.lock().unwrap();
        state_locked.app_settings.api_key = Some(api_key.clone());
        state_locked.app_settings.event_key = Some(event_key.clone());
    }

    tauri::async_runtime::spawn(write_settings(state.lock().unwrap().app_settings.clone()));

    Ok(())
}

#[tauri::command]
async fn start_sync(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state = Arc::clone(&app_state);

    info!(target: "command", "start_sync");

    {
        let mut state_locked = state.lock().unwrap();
        let app_settings = state_locked.app_settings.clone();

        if let Ok(synchronizer) = try_create_synchronizer(app_handle.clone(), app_settings) {
            state_locked.synchronizer = Some(synchronizer);
        } else {
            client_notify::sync_error(
                Arc::new(app_handle),
                "Failed to create synchronizer".to_string(),
            );
            return Err(());
        }
    }

    if let Some(synchronizer) = state.lock().unwrap().synchronizer.clone() {
        synchronizer.start().map_err(|_| ())?;
    }

    Ok(())
}

#[tauri::command]
fn stop_sync(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) {
    let state_locked = app_state.lock().unwrap();

    if let Some(synchronizer) = &state_locked.synchronizer {
        synchronizer.stop();
    }
}

fn main() {
    logger::init().expect("failed to initialize logger");

    tauri::Builder::default()
        .manage::<Arc<Mutex<AppState>>>(Default::default())
        .setup(|app| {
            let cwd = std::env::current_dir();
            info!(target: "setup", "cwd: {:?}", cwd);
            let file_contents = std::fs::read_to_string(cwd.unwrap().join("settings.json"));
            match file_contents {
                Ok(contents) => {
                    info!(target: "setup", "contents: {:?}", contents);
                    info!(target: "setup", "parsed contents: {:?}", serde_json::from_str::<AppSettings>(&contents));
                    let app_settings: AppSettings =
                        serde_json::from_str(&contents).unwrap_or_else(|_| AppSettings::default());
                    info!(target: "setup", "app_settings: {:?}", app_settings);

                    let state: tauri::State<'_, Arc<Mutex<AppState>>> = app.state();
                    let mut state_locked = state.lock().unwrap();
                    state_locked.app_settings = app_settings;
                    state_locked.app_settings.update_server_url(get_server_url());
                }
                Err(_) => {
                    info!(target: "setup", "no settings.json found");
                }
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            choose_database,
            save_settings,
            fetch_app_settings,
            fetch_database_path,
            start_sync,
            stop_sync
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
