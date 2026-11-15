<script setup>
const props = defineProps(["screen", "host", "audience"]);

function skip() {
  Net.send({ skip: true })
}
</script>

<template>
  <div class="panel">
      <p>Look at the big screen!</p>
      <button v-if="props.host" @click="skip">Skip the tutorial</button>
  </div>
</template>
