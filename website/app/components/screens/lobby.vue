<script setup>
const props = defineProps(["screen", "host", "audience"]);

const starting = ref(false);
const players = ref(1);

function start() {
  if (Net.send({ start: true })) starting.value = true;
}

Net.message.connect((data) => {
  if(data.type === "lobby_players" && props.host) {
    players.value = data.players
  }
})
</script>

<template>
  <div class="lobby panel">
    <p class="text">{{ props.screen?.text ?? "You're in! Waiting for the game to start." }}</p>
    <p v-if="props.audience" class="hint">The game is full, so you're in the audience. You'll get to trash talk and vote!</p>
    <button v-if="props.host" :disabled="starting || players < 5" @click="start">
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
