<script setup lang="ts">
import { SCREENS } from "~/registry/screens.js";
const FALLBACK = "waiting";

const screen = computed(() => Net.state.screen);
const component = computed(() => {
  const name = screen.value?.screen as string | undefined;
  return (name && (SCREENS as Record<string, any>)[name]) || SCREENS[FALLBACK];
});

Net.disconnected.connect((reason) => {
  navigateTo(reason === "left" ? "/" : { path: "/", query: { error: reason } });
});

onMounted(() => {
  if (Net.state.status === "idle" && !Net.resume()) navigateTo("/");
});
</script>

<template>
  <main class="game">
    <ClientOnly>
      <div class="shim">
        <section class="stage">
          <component
            :is="component"
            :key="screen?.screen"
            :screen="screen"
            :host="Net.state.host"
            :audience="Net.state.audience"
          />
        </section>
      </div>

      <header class="bar panel">
        <span>
          {{ Net.state.name }}<template v-if="Net.state.host"> (VIP)</template>
        </span>
        <span v-if="Net.state.status !== 'connected'" class="status">Reconnecting…</span>
        <button class="leave" @click="Net.leave()">Leave</button>
      </header>
    </ClientOnly>
  </main>
</template>

<style scoped>
.game {
  min-height: calc(100dvh - 2 * var(--frame));
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.bar {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 16px;
}

.status {
  color: var(--error);
}

.leave {
  margin-left: auto;
  font-size: 16px;
  min-height: 40px;
  padding: 0 8px;
  border-width: 10px;
}

.shim {
  flex: 1;
  display: flex;
  height: 100%;

  justify-content: center;
  align-items: center;
}

.stage {
  /* flex: 1;
  display: flex;
  flex-direction: column; */
}
</style>
