import { writable } from 'svelte/store';

export const databasePath = writable<string>("");
export const apiKey = writable<string>("");
export const eventKey = writable<string>("");
export const serverUrl = writable<string>("");