<script setup>
const props = defineProps(["screen", "host"]);

const starting = ref(false);
function start() {
  if (Net.send({ start: true })) starting.value = true;
}
</script>

<template>
  <div class="lobby panel">
    <p class="text">{{ props.screen?.text ?? "You're in! Waiting for the game to start." }}</p>
    <button v-if="props.host" :disabled="starting" @click="start">
      {{ starting ? "Starting…" : "Everybody's in! start!" }}
    </button>
    <p v-else class="hint">The VIP starts the game.</p>
  </div>
</template>

<style scoped>
.lobby {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: auto 0;
}
.text {
  font-size: 22px;
  margin: 0;
}
.hint {
  opacity: 0.6;
  margin: 0;
}
</style>
