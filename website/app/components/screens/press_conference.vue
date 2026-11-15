<script setup>
import Presentation from "./presentation.vue";
defineProps(["screen", "host", "audience"]);
</script>

<template>
  <Presentation :screen="screen" :host="host" :audience="audience" />
</template>
