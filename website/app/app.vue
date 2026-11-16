<template>
    <div>
        <NuxtRouteAnnouncer />
        <NuxtPage />
    </div>
</template>

<style>
@font-face {
    font-family: "OldNewspaperTypes";
    src: url("~/assets/fonts/OldNewspaperTypes.ttf") format("truetype");
    font-display: swap;
}

@font-face {
    font-family: "Melt-Swashes";
    src: url("~/assets/fonts/Melt-Swashes.ttf") format("truetype");
    font-display: swap;
}

:root {
    --frame: clamp(28px, 7vmin, 64px);
    --ink: #000;
    --accent: #ff9312;
    --error: #9b1c00;
    color-scheme: light;
}

*,
*::before,
*::after {
    box-sizing: border-box;
}

html,
body {
    margin: 0;
    min-height: 100%;
}

body {
    font-family: "OldNewspaperTypes", Georgia, serif;
    color: var(--ink);
    background: #6b4a2b;
    padding: var(--frame);
    min-height: 100dvh;
}

body::before {
    content: "";
    position: fixed;
    inset: 0;
    z-index: -1;
    border-style: solid;
    border-width: var(--frame);
    border-image: url("~/assets/textures/bg2.webp") 112 fill / var(--frame) stretch;
    pointer-events: none;
}

button {
    font-family: inherit;
    font-size: 20px;
    line-height: 1.1;
    color: var(--ink);
    min-height: 52px;
    padding: 4px 14px;
    border-style: solid;
    border-width: 12px;
    border-image: url("~/assets/textures/button.webp") 24 fill / 12px stretch;
    background: none;
    cursor: pointer;
    -webkit-tap-highlight-color: transparent;

    &:hover:not(:disabled),
    &:active:not(:disabled) {
        border-image-source: url("~/assets/textures/button_pressed.webp");
    }

    &:focus-visible {
        outline: 2px solid rgba(255, 255, 255, 0.75);
        outline-offset: 2px;
    }

    &:disabled {
        border-image: none;
        border-color: transparent;
        border-radius: 3px;
        border-image: url("~/assets/textures/button.webp") 24 fill / 12px stretch;
        filter: brightness(60%);
        cursor: default;
    }
}

.panel {
    border-style: solid;
    border-width: 26px 30px 10px;
    border-image: url("~/assets/textures/panel.webp") 52 60 15 fill / 26px 30px 10px stretch;
    padding: 6px 4px 18px;
}

input {
    width: 100%;
    min-width: 0;
    font-family: inherit;
    font-size: 20px;
    color: var(--ink);
    padding: 10px 12px;
    border: 2px solid #ffad4d;
    border-radius: 3px;
    background: rgba(255, 255, 255, 0.55);

    &:focus {
        outline: 2px solid rgba(255, 255, 255, 0.75);
        outline-offset: 2px;
    }

    &::placeholder {
        color: rgba(0, 0, 0, 0.4);
    }
}
</style>
