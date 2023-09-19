// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};
use tauri::Manager;

pub struct AppState {
    database_path: Arc<Mutex<Option<PathBuf>>>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            database_path: Default::default(),
        }
    }
}

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
fn open_database(app_handle: tauri::AppHandle, app_state: tauri::State<'_, AppState>) {
    println!("pick_database");
    let database_path = Arc::clone(&app_state.database_path);

    tauri::api::dialog::FileDialogBuilder::new().pick_file(move |file_path| {
        let mut database_path_locked = database_path.lock().unwrap();
        if let Some(path) = file_path {
            *database_path_locked = Some(path);
        } else {
            *database_path_locked = None;
        }

        let file_path = database_path_locked
            .as_ref()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_default();

        app_handle
            .emit_all("database_chosen", file_path)
            .expect("failed to emit event");
    });
}

fn main() {
    tauri::Builder::default()
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![greet, open_database])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
