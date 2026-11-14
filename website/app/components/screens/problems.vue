<script setup>
const props = defineProps(["screen", "host", "audience"]);
</script>

<template>
  <div v-if="!audience">

  </div>
  <div v-else>
      Look at the screen!
  </div>
</template>
