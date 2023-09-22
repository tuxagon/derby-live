extern crate log;
extern crate tauri;

use log::info;
use std::sync::Arc;
use tauri::{AppHandle, Manager};

#[derive(Debug)]
enum ServerEvent {
    DatabaseChosen(String),
    SyncStarted,
    SyncStopped,
    SyncError(String),
    SyncUpdated(String),
}

fn emit_all(app_handle: Arc<AppHandle>, server_event: ServerEvent) {
    info!(target: "command", "emit_all: {:?}", server_event);

    match server_event {
        ServerEvent::DatabaseChosen(database_path) => {
            app_handle
                .emit_all("database_chosen", database_path)
                .expect("failed to emit database_chosen");
        }
        ServerEvent::SyncStarted => {
            app_handle
                .emit_all("sync_started", ())
                .expect("failed to emit sync_started");
        }
        ServerEvent::SyncStopped => {
            app_handle
                .emit_all("sync_stopped", ())
                .expect("failed to emit sync_stopped");
        }
        ServerEvent::SyncError(message) => {
            app_handle
                .emit_all("sync_error", message)
                .expect("failed to emit sync_err");
        }
        ServerEvent::SyncUpdated(message) => {
            app_handle
                .emit_all("sync_updated", message)
                .expect("failed to emit sync_updated");
        }
    }
}

pub fn database_chosen(app_handle: Arc<AppHandle>, database_path: String) {
    emit_all(app_handle, ServerEvent::DatabaseChosen(database_path));
}

pub fn sync_started(app_handle: Arc<AppHandle>) {
    emit_all(app_handle, ServerEvent::SyncStarted);
}

pub fn sync_stopped(app_handle: Arc<AppHandle>) {
    emit_all(app_handle, ServerEvent::SyncStopped);
}

pub fn sync_error(app_handle: Arc<AppHandle>, message: String) {
    emit_all(app_handle, ServerEvent::SyncError(message));
}

pub fn sync_updated(app_handle: Arc<AppHandle>, message: String) {
    emit_all(app_handle, ServerEvent::SyncUpdated(message));
}
