<script setup>
const props = defineProps(["screen", "host", "audience"]);
</script>

<template>
  <div class="panel results">
    <p class="label">The winner is…</p>
    <h2>{{ props.screen?.winner || "Nobody!" }}</h2>
    <ol>
      <li v-for="line in props.screen?.lines ?? []" :key="line">{{ line }}</li>
    </ol>
    <p class="label">Thanks for playing!</p>
  </div>
</template>

<style scoped>
.results {
  display: flex;
  flex-direction: column;
  gap: 12px;
  text-align: center;
}
.label {
  margin: 0;
  font-size: 18px;
}
h2 {
  margin: 0;
  font-weight: normal;
  font-size: 30px;
}
ol {
  margin: 0;
  padding-left: 1.4em;
  text-align: left;
  font-size: 18px;
}
</style>
