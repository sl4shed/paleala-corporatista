<script setup>
const props = defineProps(["screen", "host", "audience"]);

const options = ref([]);
const voted = ref(null);

Net.message.connect((data) => {
  if (data?.type !== "vote") return;
  options.value = data.options ?? [];
  voted.value = null;
});

function vote(index) {
  if (Net.send({ type: "vote", index })) voted.value = index;
}
</script>

<template>
  <div class="panel vote">
    <p v-if="!options.length">Look at the big screen!</p>
    <p v-else-if="voted !== null">Vote cast! Look at the big screen.</p>
    <template v-else>
      <p class="label">Which product deserves your money?</p>
      <button v-for="o in options" :key="o.index" class="option" @click="vote(o.index)">
        <img :src="'data:image/png;base64,' + o.image" alt="" />
        <span>{{ o.title }}</span>
      </button>
    </template>
  </div>
</template>

<style scoped>
.vote {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.label {
  margin: 0;
  font-size: 18px;
  text-align: center;
}
.option {
  display: flex;
  align-items: center;
  gap: 12px;
  text-align: left;
}
.option img {
  width: 64px;
  height: 64px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 3px;
}
</style>
