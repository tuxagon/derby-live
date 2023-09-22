<script lang="ts">
  import { onMount } from "svelte";
  import { apiKey, eventKey, serverUrl } from "./stores";
  import { invoke } from "@tauri-apps/api/tauri";

  export let settingsOpen: boolean = true;

  onMount(() => {
    console.log("onMount Settings");
    invoke("fetch_app_settings").then((settings) => {
      apiKey.set(settings.apiKey as string);
      eventKey.set(settings.eventKey as string);
      serverUrl.set(settings.serverUrl as string);
    });

    return () => {};
  });

  console.log("In settings");

  let inputApiKey = "";
  let inputEventKey = "";
  let currentServerUrl = "";

  apiKey.subscribe((key) => {
    inputApiKey = key;
  });
  eventKey.subscribe((key) => {
    inputEventKey = key;
  });
  serverUrl.subscribe((url) => {
    currentServerUrl = url;
  });

  async function save() {
    apiKey.set(inputApiKey);
    eventKey.set(inputEventKey);
    await invoke("save_settings", {
      apiKey: inputApiKey,
      eventKey: inputEventKey,
    });
    settingsOpen = false;
  }
</script>

<div>
  <p>{currentServerUrl}</p>
  <form class="flex flex-row flex-wrap" on:submit|preventDefault={save}>
    <input
      id="api-key-input"
      placeholder="Enter API Key..."
      bind:value={inputApiKey}
    />
    <input
      id="event-key-input"
      placeholder="Enter Event Key..."
      bind:value={inputEventKey}
    />
    <button type="submit">Save</button>
  </form>
</div>

<style>
  input,
  button {
    @apply mr-5 mt-5;
  }
</style>
