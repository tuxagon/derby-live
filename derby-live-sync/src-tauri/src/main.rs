// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

extern crate log;
extern crate serde;
extern crate tauri;

mod app_state;
mod client_notify;
mod database;
mod logger;
mod settings;
mod synchronize;

mod app_cmds;

use app_state::AppState;
use log::info;
use settings::AppSettings;
use std::sync::{Arc, Mutex};
use tauri::Manager;

#[tauri::command]
async fn choose_database(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "command", "choose_database");
    app_cmds::choose_database(app_handle, app_state).await
}

#[tauri::command]
fn fetch_app_settings(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> AppSettings {
    info!(target: "command", "fetch_app_settings");
    app_cmds::fetch_app_settings(app_state)
}

#[tauri::command]
fn fetch_database_path(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> String {
    info!(target: "command", "fetch_database_path");
    app_cmds::fetch_database_path(app_state)
}

#[tauri::command]
async fn save_settings(
    api_key: String,
    event_key: String,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "command", "save_settings");
    app_cmds::save_settings(api_key, event_key, app_state).await
}

#[tauri::command]
async fn start_sync(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "command", "start_sync");
    app_cmds::start_sync(app_handle, app_state).await
}

#[tauri::command]
fn stop_sync(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) {
    info!(target: "command", "stop_sync");
    app_cmds::stop_sync(app_state);
}

fn main() {
    logger::init().expect("failed to initialize logger");

    tauri::Builder::default()
        .manage::<Arc<Mutex<AppState>>>(Default::default())
        .setup(|app| {
            match AppSettings::load() {
                Ok(app_settings) => {
                    let state: tauri::State<'_, Arc<Mutex<AppState>>> = app.state();

                    let mut state_locked = state.lock().unwrap();
                    state_locked.app_settings = app_settings;
                }
                Err(_) => {
                    info!(target: "setup", "no settings.json found");
                }
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            choose_database,
            fetch_app_settings,
            fetch_database_path,
            save_settings,
            start_sync,
            stop_sync,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
