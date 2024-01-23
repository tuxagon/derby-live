use crate::app_state::AppState;
use crate::client_notify;
use crate::settings::AppSettings;
use log::info;
use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};

pub async fn handle(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "command", "choose_database");

    let state = Arc::clone(&app_state);

    tauri::api::dialog::FileDialogBuilder::new().pick_file(move |file_path| {
        {
            let chosen_file_path = assign_database_path(Arc::clone(&state), file_path);

            client_notify::database_chosen(Arc::new(app_handle), chosen_file_path);
        }

        match state.lock() {
            Ok(state_locked) => {
                tauri::async_runtime::spawn(AppSettings::write(state_locked.app_settings.clone()));
            }
            Err(_) => {
                info!(target: "command", "choose_database: failed to lock app_state");
            }
        }
    });

    Ok(())
}

fn assign_database_path(app_state: Arc<Mutex<AppState>>, database_path: Option<PathBuf>) -> String {
    match app_state.lock() {
        Ok(mut state_locked) => {
            if let Some(path) = database_path {
                state_locked
                    .app_settings
                    .update_database_path_if_exists(path);
            } else {
                state_locked.app_settings.database_path = None;
            }

            state_locked.app_settings.current_database_path()
        }
        Err(_) => {
            info!(target: "command", "choose_database: failed to lock app_state");
            "".to_string()
        }
    }
}
