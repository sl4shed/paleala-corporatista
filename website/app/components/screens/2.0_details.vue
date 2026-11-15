<script setup>
const props = defineProps(["screen", "host", "audience"]);

const product = ref(null);
const description = ref("");
const sent = ref(false);

Net.message.connect((data) => {
  if (data?.type === "upgrade") {
    product.value = data;
    description.value = "";
    sent.value = false;
  } else if (data?.type === "upgrade_force_submit" && !sent.value) {
    send("upgrade_force_submit");
  }
});

function send(type) {
  if (Net.send({ type, description: description.value.trim() })) sent.value = true;
}
</script>

<template>
  <div v-if="!audience" class="panel upgrade">
    <p v-if="!product">Waiting for a product…</p>
    <p v-else-if="sent">Sent! Look at the big screen.</p>
    <form v-else @submit.prevent="description.trim() && send('upgrade')">
      <p class="label">Make version 2.0 of:</p>
      <h2>{{ product.title }}</h2>
      <img :src="'data:image/png;base64,' + product.image" alt="" />
      <p class="old">{{ product.description }}</p>
      <div v-if="product.reviews?.length" class="reviews">
        <p class="label">What people said:</p>
        <p v-for="r in product.reviews" :key="r" class="review">"{{ r }}" ★☆☆☆☆</p>
      </div>
      <label>
        What's new in 2.0?
        <textarea v-model="description" maxlength="200" rows="4" />
      </label>
      <button :disabled="!description.trim()">Send</button>
    </form>
  </div>
  <div v-else class="panel">Look at the screen!</div>
</template>

<style scoped>
form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
h2 {
  margin: 0;
  font-weight: normal;
  font-size: 26px;
}
.label,
.old {
  margin: 0;
  font-size: 16px;
}
.reviews {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.review {
  margin: 0;
  font-size: 15px;
  font-style: italic;
}
img {
  width: 60%;
  align-self: center;
  aspect-ratio: 1;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  background: #fff;
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
</style>
