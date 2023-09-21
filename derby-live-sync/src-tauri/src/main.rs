// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod sync;

use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};
use tauri::Manager;

struct AppState {
    database_path: Option<PathBuf>,
    api_key: Option<String>,
    event_key: Option<String>,
    synchronizer: Option<sync::Synchronizer>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            database_path: Default::default(),
            api_key: Default::default(),
            event_key: Default::default(),
            synchronizer: Default::default(),
        }
    }
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
async fn open_database(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state = Arc::clone(&app_state);

    tauri::api::dialog::FileDialogBuilder::new().pick_file(move |file_path| {
        {
            let mut state_locked = state.lock().unwrap();
            if let Some(path) = file_path {
                state_locked.database_path = Some(path);
            } else {
                state_locked.database_path = None;
            }

            let file_path = state_locked
                .database_path
                .as_ref()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default();

            app_handle
                .emit_all("database_chosen", file_path)
                .expect("failed to emit event");
        }

        let current_api_key = state.lock().unwrap().api_key.clone();
        let current_event_key = state.lock().unwrap().event_key.clone();
        let current_database_path = state.lock().unwrap().database_path.clone();

        let write_async = write_settings(current_api_key, current_event_key, current_database_path);
        tauri::async_runtime::spawn(write_async);
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
    {
        let mut state_locked = state.lock().unwrap();
        state_locked.api_key = Some(api_key);
        state_locked.event_key = Some(event_key);
    }

    let current_api_key = state.lock().unwrap().api_key.clone();
    let current_event_key = state.lock().unwrap().event_key.clone();
    let current_database_path = state.lock().unwrap().database_path.clone();

    write_settings(current_api_key, current_event_key, current_database_path)
        .await
        .map_err(|_| ())?;

    Ok(())
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct SettingsForm {
    api_key: String,
    event_key: String,
}

#[tauri::command]
fn fetch_settings(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> SettingsForm {
    println!("get_settings");
    let state_locked = app_state.lock().unwrap();

    let api_key = state_locked.api_key.clone().unwrap_or_default();
    let event_key = state_locked.event_key.clone().unwrap_or_default();
    println!("api_key: {}", api_key);
    println!("event_key: {}", event_key);

    SettingsForm {
        api_key: state_locked.api_key.clone().unwrap_or_default(),
        event_key: state_locked.event_key.clone().unwrap_or_default(),
    }
}

#[tauri::command]
fn fetch_database_path(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> String {
    let state_locked = app_state.lock().unwrap();
    state_locked
        .database_path
        .as_ref()
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_default()
}

#[tauri::command]
async fn start_sync(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state = Arc::clone(&app_state);
    {
        let mut state_locked = state.lock().unwrap();
        let database_path = state_locked.database_path.clone().unwrap_or_default();
        state_locked.synchronizer =
            Some(sync::Synchronizer::new(database_path, app_handle.clone()));
    }

    if let Some(synchronizer) = &state.lock().unwrap().synchronizer {
        synchronizer.start();
        app_handle
            .emit_all("sync_started", ())
            .expect("failed to emit event");
    }

    Ok(())
}

#[tauri::command]
async fn stop_sync(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    let state_locked = app_state.lock().unwrap();

    if let Some(synchronizer) = &state_locked.synchronizer {
        synchronizer.stop();
        app_handle
            .emit_all("sync_stopped", ())
            .expect("failed to emit event");
    }

    Ok(())
}

#[derive(serde::Serialize, serde::Deserialize)]
struct SavedSettings {
    api_key: String,
    event_key: String,
    database_path: String,
}

async fn write_settings(
    api_key: Option<String>,
    event_key: Option<String>,
    database_path: Option<PathBuf>,
) -> Result<(), tauri::Error> {
    let saved_settings = SavedSettings {
        api_key: api_key.unwrap_or_default(),
        event_key: event_key.unwrap_or_default(),
        database_path: database_path
            .unwrap_or_default()
            .to_string_lossy()
            .to_string(),
    };

    tauri::async_runtime::spawn(async move {
        let cwd = std::env::current_dir();
        println!("cwd: {:?}", cwd);
        let file_path = cwd.unwrap().join("settings.json");
        let file_contents = serde_json::to_string_pretty(&saved_settings).unwrap();
        std::fs::write(file_path, file_contents).unwrap();
    })
    .await?;

    Ok(())
}

fn main() {
    tauri::Builder::default()
        .manage::<Arc<Mutex<AppState>>>(Default::default())
        .setup(|app| {
            let cwd = std::env::current_dir();
            let file_contents = std::fs::read_to_string(cwd.unwrap().join("settings.json"));
            match file_contents {
                Ok(contents) => {
                    let saved_settings: SavedSettings = serde_json::from_str(&contents)
                        .unwrap_or_else(|_| SavedSettings {
                            api_key: "".to_string(),
                            event_key: "".to_string(),
                            database_path: "".to_string(),
                        });

                    let state: tauri::State<'_, Arc<Mutex<AppState>>> = app.state();
                    let mut state_locked = state.lock().unwrap();
                    state_locked.api_key = Some(saved_settings.api_key);
                    state_locked.event_key = Some(saved_settings.event_key);
                    state_locked.database_path = Some(PathBuf::from(saved_settings.database_path));
                }
                Err(_) => {
                    println!("No settings file found");
                }
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            greet,
            open_database,
            save_settings,
            fetch_settings,
            fetch_database_path,
            start_sync,
            stop_sync
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
