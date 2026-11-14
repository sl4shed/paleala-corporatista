// Phone-side mirror of the Godot `Net` autoload (game/scripts/net.gd).
// Nuxt auto-imports this, so `Net` is available in every component.
//
// Usage:
//   Net.join("ABCD", "Ana")
//   Net.message.connect((data) => { ... })   // auto-disconnects when the component unmounts
//   Net.send({ answer: "socks" })
//   Net.state.status / Net.state.roomCode    // reactive, use in templates

import { reactive, getCurrentScope, onScopeDispose } from "vue";

export class Signal<A extends unknown[] = []> {
  private handlers = new Set<(...args: A) => void>();

  connect(fn: (...args: A) => void): () => void {
    if (import.meta.server) return () => {}; // never keep handlers from SSR
    this.handlers.add(fn);
    const off = () => this.disconnect(fn);
    if (getCurrentScope()) onScopeDispose(off);
    return off;
  }

  once(fn: (...args: A) => void): () => void {
    const off = this.connect((...args) => {
      off();
      fn(...args);
    });
    return off;
  }

  disconnect(fn: (...args: A) => void) {
    this.handlers.delete(fn);
  }

  emit(...args: A) {
    for (const fn of [...this.handlers]) {
      try {
        fn(...args);
      } catch (e) {
        console.error("[Net] signal handler threw", e);
      }
    }
  }
}

export type NetStatus = "idle" | "connecting" | "connected" | "reconnecting";
export type NetError =
  "no_room" | "room_full" | "connection_lost" | (string & {});

const RECONNECT_DELAY_MS = 1500;
const RECONNECT_TRIES = 10;
const FINAL_CLOSE_CODES = new Set([4000, 4001, 4002]); // error, replaced by another tab, host left

function load(key: string) {
  try {
    return localStorage.getItem(key) ?? "";
  } catch {
    return "";
  }
}
function save(key: string, value: string) {
  try {
    localStorage.setItem(key, value);
  } catch {}
}

/** A message switches screens if it has a `screen` name and its type is "screen" (or it has no type). */
function isScreen(data: any): boolean {
  return (
    !!data &&
    typeof data === "object" &&
    typeof data.screen === "string" &&
    (data.type === undefined || data.type === "screen")
  );
}

class NetClient {
  readonly joined = new Signal<[id: string, code: string]>();
  readonly message = new Signal<[data: any]>();
  /** The host switched the phone to a new screen ({ type: "screen", screen: "name", ... }). */
  readonly screenChanged = new Signal<[screen: any]>();
  readonly hostLeft = new Signal();
  readonly error = new Signal<[reason: NetError]>();
  readonly disconnected = new Signal<[reason: NetError | "left"]>();

  readonly state = reactive({
    status: "idle" as NetStatus,
    roomCode: "",
    playerId: "",
    name: "",
    lastMessage: null as any,
    /** Last screen message from the host, e.g. { type: "screen", screen: "tutorial", ... }. */
    screen: null as any,
    /** True if this player is the VIP (Godot sends { host: true }). */
    host: false,
  });

  private ws: WebSocket | null = null;
  private tries = 0;
  private retryTimer: ReturnType<typeof setTimeout> | undefined;
  private leaving = false;

  get pid(): string {
    let pid = load("net:pid");
    if (!pid) {
      pid =
        crypto.randomUUID?.() ??
        Math.random().toString(36).slice(2) + Date.now().toString(36);
      save("net:pid", pid);
    }
    return pid;
  }

  get savedName(): string {
    return load("net:name");
  }

  get savedRoom(): string {
    return load("net:room");
  }

  isOpen(): boolean {
    return (
      this.ws?.readyState === WebSocket.OPEN &&
      this.state.status === "connected"
    );
  }

  /** Join a room */
  join(code: string, name: string) {
    code = code.trim().toUpperCase();
    name = name.trim();
    if (!code || !name) return;

    this.close(false);
    this.leaving = false;
    this.tries = 0;
    this.state.roomCode = code;
    this.state.name = name;

    save("net:name", name);
    this.connectSocket();
  }

  /** Rejoin the room from before a page refresh */
  resume(): boolean {
    const code = load("net:room");
    const name = load("net:name");
    if (!code || !name) return false;

    this.join(code, name);
    return true;
  }

  /** Send anything to the host */
  send(data: unknown) {
    if (!this.isOpen()) {
      console.warn("[Net] send() while not connected, dropped:", data);
      return false;
    }

    this.ws!.send(JSON.stringify({ data }));
    return true;
  }

  /** Leave the room on purpose */
  leave() {
    this.close(true);
    this.disconnected.emit("left");
  }

  // internal bullshi //
  private close(forget: boolean) {
    this.leaving = true;
    clearTimeout(this.retryTimer);
    if (this.ws) {
      this.ws.onclose = this.ws.onmessage = this.ws.onopen = null;
      this.ws.close();
      this.ws = null;
    }
    this.state.status = "idle";
    if (forget) {
      save("net:room", "");
      this.state.roomCode = "";
      this.state.playerId = "";
      this.state.lastMessage = null;
      this.state.screen = null;
      this.state.host = false;
    }
  }

  private connectSocket() {
    const q = new URLSearchParams({
      role: "player",
      code: this.state.roomCode,
      name: this.state.name,
      pid: this.pid,
    });
    const proto = location.protocol === "https:" ? "wss" : "ws";
    const ws = new WebSocket(`${proto}://${location.host}/ws?${q}`);
    this.ws = ws;
    this.state.status = this.tries > 0 ? "reconnecting" : "connecting";

    ws.onmessage = (e) => this.handle(e.data);
    ws.onclose = (e) => {
      if (this.ws !== ws) return;
      this.ws = null;
      if (this.leaving || FINAL_CLOSE_CODES.has(e.code)) {
        this.state.status = "idle";
        return;
      }
      if (this.tries < RECONNECT_TRIES) {
        this.tries++;
        this.state.status = "reconnecting";
        this.retryTimer = setTimeout(
          () => this.connectSocket(),
          RECONNECT_DELAY_MS,
        );
      } else {
        this.close(true);
        this.error.emit("connection_lost");
        this.disconnected.emit("connection_lost");
      }
    };
  }

  private handle(text: string) {
    let m: any;
    try {
      m = JSON.parse(text);
    } catch {
      return;
    }
    switch (m?.type) {
      case "joined":
        this.tries = 0;
        this.state.status = "connected";
        this.state.playerId = m.id;
        this.state.roomCode = m.code;
        save("net:room", m.code);
        this.joined.emit(m.id, m.code);
        break;
      case "msg":
        this.state.lastMessage = m.data;
        if (typeof m.data?.host === "boolean") this.state.host = m.data.host;
        if (isScreen(m.data)) {
          this.state.screen = m.data;
          this.screenChanged.emit(m.data);
        }
        this.message.emit(m.data);
        break;
      case "error":
        this.close(true);
        this.error.emit(m.reason);
        this.disconnected.emit(m.reason);
        break;
      case "host_left":
        this.close(true);
        this.hostLeft.emit();
        this.disconnected.emit("host_left");
        break;
    }
  }
}

/** The one shared connection, like a Godot autoload. */
export const Net = new NetClient();
