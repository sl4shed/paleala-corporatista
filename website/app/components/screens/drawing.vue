<script setup>
const props = defineProps(["screen", "host", "audience"]);

const SIZE = 600;
const COLORS = [
  "#1b1b1b",
  "#d62828",
  "#1d4ed8",
  "#2a9d3c",
  "#f4b400",
  "#8b4513",
  "#ff7ab6",
  "#ffffff",
];
const BRUSHES = [4, 10, 24];

const canvas = ref();
const product = ref(null);
const sent = ref(false);
const color = ref(COLORS[0]);
const brush = ref(BRUSHES[1]);
const strokes = ref([]);
let current = null;
let background = null;

Net.message.connect((data) => {
  if (data?.type === "drawing") {
    product.value = data;
    strokes.value = [];
    sent.value = false;
    background = null;
    if (data.background) {
      const img = new Image();
      img.onload = () => {
        background = img;
        redraw();
      };
      img.src = "data:image/png;base64," + data.background;
    }
    nextTick(redraw);
  } else if (data?.type === "drawing_force_submit" && !sent.value) {
    send("drawing_force_submit");
  }
});

onMounted(redraw);

function ctx() {
  return canvas.value?.getContext("2d");
}

function point(e) {
  const r = canvas.value.getBoundingClientRect();
  return [
    ((e.clientX - r.left) / r.width) * SIZE,
    ((e.clientY - r.top) / r.height) * SIZE,
  ];
}

function paint(c, stroke) {
  c.strokeStyle = stroke.color;
  c.fillStyle = stroke.color;
  c.lineWidth = stroke.size;
  c.lineCap = "round";
  c.lineJoin = "round";
  const [first, ...rest] = stroke.points;
  if (!rest.length) {
    c.beginPath();
    c.arc(first[0], first[1], stroke.size / 2, 0, Math.PI * 2);
    c.fill();
    return;
  }
  c.beginPath();
  c.moveTo(...first);
  for (const p of rest) c.lineTo(...p);
  c.stroke();
}

function redraw() {
  const c = ctx();
  if (!c) return;
  c.fillStyle = "#ffffff";
  c.fillRect(0, 0, SIZE, SIZE);
  if (background) c.drawImage(background, 0, 0, SIZE, SIZE);
  for (const s of strokes.value) paint(c, s);
}

function down(e) {
  if (sent.value) return;
  canvas.value.setPointerCapture(e.pointerId);
  current = { color: color.value, size: brush.value, points: [point(e)] };
  paint(ctx(), current);
}

function move(e) {
  if (!current) return;
  const p = point(e);
  const last = current.points.at(-1);
  current.points.push(p);
  const c = ctx();
  c.strokeStyle = current.color;
  c.lineWidth = current.size;
  c.lineCap = "round";
  c.beginPath();
  c.moveTo(...last);
  c.lineTo(...p);
  c.stroke();
}

function up() {
  if (!current) return;
  strokes.value.push(current);
  current = null;
}

function undo() {
  strokes.value.pop();
  redraw();
}

function clear() {
  strokes.value = [];
  redraw();
}

function send(type) {
  if (!canvas.value) return;
  const image = canvas.value.toDataURL("image/png").split(",")[1];
  if (Net.send({ type, image })) sent.value = true;
}
</script>

<template>
  <div v-if="!audience" class="panel drawing">
    <p v-if="!product">Waiting for your product…</p>
    <p v-else-if="sent">Sent! Look at the big screen.</p>

    <template v-if="product && !sent">
      <div class="product">
        <p class="label">{{ product.label ?? "Draw your product:" }}</p>
        <h2>{{ product.title }}</h2>
        <p v-if="product.description" class="description">{{ product.description }}</p>
      </div>
    </template>

    <canvas
      v-show="product && !sent"
      ref="canvas"
      :width="SIZE"
      :height="SIZE"
      @pointerdown="down"
      @pointermove="move"
      @pointerup="up"
      @pointercancel="up"
    />

    <template v-if="product && !sent">
      <div class="colors">
        <button
          v-for="c in COLORS"
          :key="c"
          class="swatch"
          :class="{ active: color === c }"
          :style="{ background: c }"
          @click="color = c"
        />
      </div>
      <div class="tools">
        <button
          v-for="b in BRUSHES"
          :key="b"
          class="brush"
          :class="{ active: brush === b }"
          @click="brush = b"
        >
          <span :style="{ width: b + 'px', height: b + 'px', background: color }" />
        </button>
        <button @click="undo" :disabled="!strokes.length">Undo</button>
        <button @click="clear" :disabled="!strokes.length">Clear</button>
      </div>
      <button @click="send('drawing')" :disabled="!strokes.length">Send</button>
    </template>
  </div>
  <div v-else class="panel">Look at the screen!</div>
</template>

<style scoped>
.drawing {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.product h2 {
  margin: 0;
  font-weight: normal;
  font-size: 26px;
}
.label,
.description {
  margin: 0;
  font-size: 16px;
}
canvas {
  width: 100%;
  aspect-ratio: 1;
  background: #fff;
  border: 2px solid #ffad4d;
  border-radius: 3px;
  touch-action: none;
  display: block;
}
.colors {
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  gap: 6px;
}
.swatch {
  aspect-ratio: 1;
  min-width: 0;
  padding: 0;
  border: 2px solid rgba(0, 0, 0, 0.35);
  border-radius: 50%;
  border-image: none;
}
.swatch.active {
  outline: 3px solid #ffad4d;
  outline-offset: 2px;
}
.tools {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.tools button {
  flex: 1;
}
.brush {
  display: grid;
  place-items: center;
}
.brush span {
  display: block;
  border-radius: 50%;
  border: 1px solid rgba(0, 0, 0, 0.3);
}
.brush.active {
  outline: 3px solid #ffad4d;
  outline-offset: 2px;
}
</style>
