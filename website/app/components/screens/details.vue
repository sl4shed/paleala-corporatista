<script setup>
const props = defineProps(["screen", "host", "audience"]);

const buzzwords = ref([]);
const title = ref("");
const description = ref("");
const problem = ref("");
const error = ref();
const sent = ref(false);

const ready = computed(() => title.value.trim() && description.value.trim());

Net.message.connect((data) => {
  if (data?.type === "details") {
    buzzwords.value = data.buzzwords ?? [];
    title.value = "";
    description.value = "";
    sent.value = false;
    problem.value = data.problem ?? "";
  } else if (data?.type === "details_force_submit" && !sent.value) {
    send("details_force_submit");
  }
});

function send(type) {
  if(!description.value.includes(buzzwords.value[0]) || !description.value.includes(buzzwords.value[1]) || !description.value.includes(buzzwords.value[3])) {
    error.value = "Your description doesn't include the words provided!!"
    return;
  }

  const ok = Net.send({
    type,
    title: title.value.trim(),
    description: description.value.trim(),
  });
  if (ok) sent.value = true;
}
</script>

<template>
  <div v-if="!audience" class="panel">
    <p v-if="!buzzwords.length">Waiting for your buzzwords…</p>
    <p v-else-if="sent">Sent! Look at the big screen.</p>
    <form v-else @submit.prevent="ready && send('details')">
      <div>
        <p>The problem that you have to solve:</p>
        {{ problem.text }}
      </div>

      <p class="label">Your product must include:</p>
      <ul class="buzzwords">
        <li v-for="word in buzzwords" :key="word">{{ word }}</li>
      </ul>
      <label>
        Product name
        <input v-model="title" maxlength="40" autocomplete="off" />
      </label>
      <label>
        Product Description
        <textarea v-model="description" maxlength="200" rows="4" class="description" />
      </label>

      <p v-if="error" class="error">{{ error }}</p>
      <button :disabled="!ready">Send</button>
    </form>
  </div>
  <div v-else>Look at the screen!</div>
</template>

<style scoped>
form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.label {
  margin: 0;
  font-size: 18px;
}
.buzzwords {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.buzzwords li {
  padding: 4px 10px;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.55);
  font-size: 18px;
}
label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 18px;
}
textarea {
  width: 100%;
  font-family: inherit;
  font-size: 20px;
  color: var(--ink);
  padding: 10px 12px;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.55);
  resize: vertical;
}
textarea:focus {
  outline: 2px solid rgba(255, 255, 255, 0.75);
  outline-offset: 2px;
}
</style>
