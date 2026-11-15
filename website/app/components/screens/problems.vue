<script setup>
const props = defineProps(["screen", "host", "audience"]);

const problem = ref(null);
const blanks = ref([]);
const sent = ref(false);

Net.message.connect((data) => {
    if (data?.type !== "problem") return;
    problem.value = data.problem;
    blanks.value = Array(data.problem.blanks).fill("");
    sent.value = false;
});

const parts = computed(() => problem.value?.text.split("___") ?? []);
function submit() {
    if (Net.send({ blanks: blanks.value.map((a) => a.trim()) }))
        sent.value = true;
}
</script>

<template>
    <div v-if="!audience" class="panel">
        <p v-if="!problem">Waiting for your problem…</p>
        <p v-else-if="sent">Sent!</p>
        <form v-else @submit.prevent="submit">
            <p class="sentence">
                <template v-for="(part, i) in parts" :key="i">
                    {{ part }}
                    <input
                        v-if="i < problem.blanks"
                        v-model="blanks[i]"
                        class="blank"
                        :size="Math.max(5, blanks[i].length + 1)"
                        maxlength="40"
                        autocomplete="off"
                    />
                </template>
            </p>
            <button :disabled="blanks.some((a) => !a.trim())">Send</button>
        </form>
    </div>
    <div v-else>Look at the screen!</div>
</template>

<style scoped>
form {
    display: flex;
    flex-direction: column;
    gap: 16px;
}
.sentence {
    margin: 0;
    font-size: 24px;
    line-height: 2;
}
.blank {
    display: inline-block;
    width: auto;
    max-width: 100%;
    font-size: 22px;
    padding: 0 6px;
    margin: 0 2px;
    line-height: 1.4;
    border-width: 0 0 2px;
    border-radius: 0;
    vertical-align: baseline;
}
</style>
