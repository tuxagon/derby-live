use crate::app_state::AppState;
use crate::client_notify;
use crate::settings::AppSettings;
use crate::synchronize::{SyncCreationError, SyncState, Synchronizer};
use log::info;
use std::sync::{Arc, Mutex};

pub async fn handle(
    app_handle: tauri::AppHandle,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "start_sync", "handle");
    let state = Arc::clone(&app_state);

    {
        match state.lock() {
            Ok(mut state_locked) => {
                let app_settings = state_locked.app_settings.clone();

                if let Ok(synchronizer) = try_create_synchronizer(app_handle.clone(), app_settings)
                {
                    state_locked.synchronizer = Some(synchronizer);
                } else {
                    client_notify::sync_error(
                        Arc::new(app_handle),
                        "Failed to create synchronizer".to_string(),
                    );
                    return Err(());
                }
            }
            Err(_) => {
                info!(target: "start_sync", "handle: failed to lock app_state");
            }
        }
    }

    match state.lock() {
        Ok(state_locked) => {
            if let Some(synchronizer) = state_locked.synchronizer.clone() {
                synchronizer.start().map_err(|_| ())?;
            }
        }
        Err(_) => {
            info!(target: "start_sync", "handle: failed to lock app_state");
        }
    }

    Ok(())
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
