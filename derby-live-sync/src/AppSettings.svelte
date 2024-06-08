<script lang="ts">
  import { onMount } from "svelte";
  import { apiKey, eventKey, serverUrl } from "./lib/stores";
  import { invoke } from "@tauri-apps/api/tauri";
  import { WebviewWindow } from "@tauri-apps/api/window";

  onMount(() => {
    console.log("onMount Settings");
    invoke("fetch_app_settings").then((settings: any) => {
      apiKey.set(settings.apiKey as string);
      eventKey.set(settings.eventKey as string);
      serverUrl.set(settings.serverUrl as string);
    });

    return () => {};
  });

  console.log("In settings");

  let inputApiKey = "";
  let inputEventKey = "";
  let inputServerUrl = "";

  apiKey.subscribe((key) => {
    inputApiKey = key;
  });
  eventKey.subscribe((key) => {
    inputEventKey = key;
  });
  serverUrl.subscribe((url) => {
    inputServerUrl = url;
  });

  async function save() {
    apiKey.set(inputApiKey);
    eventKey.set(inputEventKey);
    serverUrl.set(inputServerUrl);
    await invoke("save_settings", {
      apiKey: inputApiKey,
      eventKey: inputEventKey,
      serverUrl: inputServerUrl,
    });
    WebviewWindow.getByLabel("manageAppSettings")
      ?.close()
      .then(() => {
        console.log("closed");
      });
  }
</script>

<main class="px-4">
  <h1>App Settings</h1>

  <form class="flex flex-col flex-wrap" on:submit|preventDefault={save}>
    <fieldset>
      <label for="api-key-input">API Key</label>
      <input
        id="api-key-input"
        placeholder="Enter API Key..."
        bind:value={inputApiKey}
      />
    </fieldset>
    <fieldset>
      <label for="event-key-input">Event Key</label>
      <input
        id="event-key-input"
        placeholder="Enter Event Key..."
        bind:value={inputEventKey}
      />
    </fieldset>
    <fieldset>
      <label for="server-url-input">Server URL</label>
      <input
        id="server-url-input"
        placeholder="Enter Server URL..."
        bind:value={inputServerUrl}
      />
    </fieldset>
    <button type="submit">Save</button>
  </form>
</main>

<style>
  h1 {
    @apply text-4xl font-bold text-orange-600 py-2 border-b-2 border-orange-600 border-solid;
  }

  input,
  button {
    @apply mr-5 mt-5;
  }
</style>
