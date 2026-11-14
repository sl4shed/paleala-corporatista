<script setup>
const ERRORS = {
  no_room: "No game with that code.",
  room_full: "That game is full.",
  connection_lost: "Lost connection.",
  host_left: "The game ended.",
};

const route = useRoute();
const code = ref(String(route.query.code ?? "").toUpperCase());
const name = ref("");

// /game sends you back here with ?error=<reason> if you get kicked out
const error = ref(ERRORS[route.query.error] ?? (route.query.error ? String(route.query.error) : ""));
const sent = ref(false);

const status = computed(() => Net.state.status === "idle" ? "form" : Net.state.status === "connected" ? "playing" : "connecting",);

Net.joined.connect(() => {
  error.value = "";
  navigateTo("/game");
});
Net.disconnected.connect((reason) => {
  if (reason !== "left") error.value = ERRORS[reason] ?? reason;
});

onMounted(() => {
  name.value = Net.savedName;
  if (Net.state.status === "connected") return navigateTo("/game");
  if (Net.state.status === "idle" && (!code.value || code.value === Net.savedRoom)) {
    Net.resume();
  }
});

function join() {
  if (code.value.trim().length !== 4 || !name.value.trim()) return;
  error.value = "";
  Net.join(code.value, name.value);
}

function submit(data) {
  if (Net.send(data)) sent.value = true;
}
</script>

<template>
  <main class="play">
    <form v-if="status === 'form'" class="card panel" @submit.prevent="join">
      <h1>Join game</h1>
      <label>
        Room code
        <input
          v-model="code"
          maxlength="4"
          autocapitalize="characters"
          autocomplete="off"
          placeholder="ABCD"
          class="code"
        />
      </label>
      <label>
        Name
        <input v-model="name" maxlength="16" autocomplete="nickname" placeholder="Your name" />
      </label>
      <p v-if="error" class="error">{{ error }}</p>
      <button :disabled="code.trim().length !== 4 || !name.trim()">Join</button>
    </form>

    <div v-else-if="status === 'connecting'" class="card panel center">Connecting…</div>
    <div v-else class="card panel center">Joining…</div>
  </main>
</template>

<style scoped>
html, body {
    margin: 0;
    overflow: none;
    color: black;
}

.play {
  min-height: calc(100dvh - 2 * var(--frame));
  display: grid;
  place-items: center;
}

.card {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.card form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.center {
  text-align: center;
  font-size: 22px;
}
h1 {
  margin: 0;
  font-size: 34px;
  font-weight: normal;
  text-align: center;
}
label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 18px;
}
.code {
  text-transform: uppercase;
  letter-spacing: 0.3em;
  font-size: 28px;
  text-align: center;
}
.error {
  color: var(--error);
  margin: 0;
}
.who {
  margin: 0;
  font-size: 14px;
}
.text {
  font-size: 20px;
  margin: 0;
}
</style>
