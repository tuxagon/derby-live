<script lang="ts">
  import Greet from "./lib/Greet.svelte";
  import DatabasePicker from "./lib/DatabasePicker.svelte";
  import Topbar from "./lib/Topbar.svelte";
  import SyncControls from "./lib/SyncControls.svelte";
</script>

<main class="px-4">
  <Topbar />

  <h1>Derby Live Sync</h1>

  <div class="m-0 mt-6 flex flex-col justify-center items-center">
    <DatabasePicker />
  </div>

  <SyncControls />
</main>

<style>
  h1 {
    @apply text-4xl font-bold text-orange-600 py-2 border-b-2 border-orange-600 border-solid;
  }
</style>
