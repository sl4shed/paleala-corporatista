<script setup>
import Drawing from "./drawing.vue";
defineProps(["screen", "host", "audience"]);
</script>

<template>
  <Drawing :screen="screen" :host="host" :audience="audience" />
</template>
