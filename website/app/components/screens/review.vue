<script setup>
const props = defineProps(["screen", "host", "audience"]);

const products = ref([]);
const reviews = ref({});
const sent = ref(false);

Net.message.connect((data) => {
  if (data?.type === "review") {
    products.value = data.products ?? [];
    reviews.value = {};
    sent.value = false;
  } else if (data?.type === "review_force_submit" && !sent.value) {
    send("review_force_submit");
  }
});

const ready = computed(() => Object.values(reviews.value).some((r) => r?.trim()));

function send(type) {
  if (Net.send({ type, reviews: reviews.value })) sent.value = true;
}
</script>

<template>
  <div class="panel review">
    <p v-if="!products.length">Look at the big screen!</p>
    <p v-else-if="sent">Reviews posted! Look at the big screen.</p>
    <form v-else @submit.prevent="ready && send('review')">
      <p class="label">Leave a nasty review. Be brutal.</p>
      <div v-for="p in products" :key="p.index" class="product">
        <h2>{{ p.title }}</h2>
        <img :src="'data:image/png;base64,' + p.image" alt="" />
        <p class="description">{{ p.description }}</p>
        <textarea v-model="reviews[p.index]" maxlength="140" rows="2" placeholder="★☆☆☆☆" />
      </div>
      <button :disabled="!ready">Post reviews</button>
    </form>
  </div>
</template>

<style scoped>
form,
.product {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.product {
  padding-bottom: 14px;
  border-bottom: 2px dashed #ffad4d;
}
h2 {
  margin: 0;
  font-weight: normal;
  font-size: 24px;
}
.label,
.description {
  margin: 0;
  font-size: 16px;
}
img {
  width: 50%;
  align-self: center;
  aspect-ratio: 1;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  background: #fff;
}
textarea {
  width: 100%;
  font-family: inherit;
  font-size: 18px;
  color: var(--ink);
  padding: 8px 10px;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.55);
  resize: vertical;
}
</style>
