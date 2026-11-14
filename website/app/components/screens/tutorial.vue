<script setup>
const props = defineProps(["screen", "host", "audience"]);

function skip() {
  Net.send({ skip: true })
}
</script>

<template>
  <div>
      Look at the big screen!
      <button v-if="props.host" @click="skip">Skip the tutorial</button>
  </div>
</template>
