<script setup>
const props = defineProps(["screen", "host", "audience"]);

const PARTS = [
  { key: "title", label: "Show the name" },
  { key: "description", label: "Show the description" },
  { key: "image", label: "Show the drawing" },
];

const state = ref(null);
const shown = ref([]);

Net.message.connect((data) => {
  if (data?.type !== "presentation") return;
  state.value = data;
  shown.value = data.shown ?? [];
});

function show(part) {
  if (Net.send({ type: "present_show", part })) shown.value.push(part);
}

function done() {
  Net.send({ type: "present_done" });
  state.value = { done: true };
}
</script>

<template>
  <div class="panel presentation">
    <p v-if="!state">Look at the big screen!</p>
    <p v-else-if="state.done">Nice pitch! Look at the big screen.</p>

    <template v-else-if="state.presenting">
      <h2>You're presenting!</h2>
      <p v-if="state.problem" class="hint">Your problem: "{{ state.problem }}"</p>
      <p class="product">Someone fixed it with: {{ state.title }}</p>
      <p class="hint">Pitch it to the investors. Reveal things when you're ready.</p>
      <button
        v-for="p in PARTS"
        :key="p.key"
        :disabled="shown.includes(p.key)"
        @click="show(p.key)"
      >
        {{ p.label }}
      </button>
      <button class="done" @click="done">Finish presentation</button>
    </template>

    <template v-else>
      <h2>{{ state.presenter }} is presenting</h2>
      <p>Look at the big screen!</p>
    </template>
  </div>
</template>

<style scoped>
.presentation {
  display: flex;
  flex-direction: column;
  gap: 12px;
  text-align: center;
}
h2 {
  margin: 0;
  font-weight: normal;
  font-size: 28px;
}
.product {
  margin: 0;
  font-size: 24px;
}
.hint {
  margin: 0;
  font-size: 16px;
}
.done {
  margin-top: 10px;
}
</style>
