<script lang="ts">
  import Greet from "./lib/Greet.svelte";
  import DatabasePicker from "./lib/DatabasePicker.svelte";
  import Topbar from "./lib/Topbar.svelte";
</script>

<main class="px-4">
  <Topbar />

  <h1>Derby Live Sync</h1>

  <div class="container">
    <DatabasePicker />
  </div>

  <div class="row">
    <a href="https://vitejs.dev" target="_blank">
      <img src="/vite.svg" class="logo vite" alt="Vite Logo" />
    </a>
    <a href="https://tauri.app" target="_blank">
      <img src="/tauri.svg" class="logo tauri" alt="Tauri Logo" />
    </a>
    <a href="https://svelte.dev" target="_blank">
      <img src="/svelte.svg" class="logo svelte" alt="Svelte Logo" />
    </a>
  </div>

  <p>Click on the Tauri, Vite, and Svelte logos to learn more.</p>

  <div class="row">
    <Greet />
  </div>
</main>

<style>
  h1 {
    @apply text-4xl font-bold text-orange-600 py-2 border-b-2 border-orange-600 border-solid;
  }

  .container {
    @apply m-0 pt-6 flex flex-col justify-center items-center;
  }

  .logo.vite:hover {
    filter: drop-shadow(0 0 2em #747bff);
  }

  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00);
  }
</style>
