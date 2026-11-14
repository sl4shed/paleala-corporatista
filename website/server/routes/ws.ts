// amazing websocket
import type { Peer } from "crossws";

type Player = { peer: Peer; name: string, metadata: Record<any, any> };
type Room = { host: Peer; players: Map<string, Player> };
type PeerInfo = { code: string; pid?: string }; // pid undefined => host

const rooms = new Map<string, Room>();
const peers = new Map<string, PeerInfo>(); // peer.id -> info

const MAX_PLAYERS = 12;
const ALPHABET = "BCDFGHJKLMNPQRSTVWXZ";

function newCode() {
  let code: string;
  do {
    code = Array.from(
      { length: 4 },
      () => ALPHABET[Math.floor(Math.random() * ALPHABET.length)],
    ).join("");
  } while (rooms.has(code));
  return code;
}

function send(peer: Peer, msg: object) {
  try {
    peer.send(JSON.stringify(msg));
  } catch {
    // peer already gone; close() will clean up
  }
}

function fail(peer: Peer, reason: string) {
  send(peer, { type: "error", reason });
  peer.close(4000, reason);
}

export default defineWebSocketHandler({
  open(peer) {
    const q = new URL(peer.request?.url ?? "", "http://x").searchParams;

    if (q.get("role") === "host") {
      const code = newCode();
      rooms.set(code, { host: peer, players: new Map() });
      peers.set(peer.id, { code });
      send(peer, { type: "room", code });
      return;
    }

    const code = (q.get("code") ?? "").trim().toUpperCase();
    const room = rooms.get(code);
    if (!room) return fail(peer, "no_room");

    const name = (q.get("name") ?? "").trim().slice(0, 16) || "Player";
    const pid = (q.get("pid") ?? "").slice(0, 64) || peer.id;

    const existing = room.players.get(pid);
    if (!existing && room.players.size >= MAX_PLAYERS) return fail(peer, "room_full");

    if (existing && existing.peer.id !== peer.id) {
      // Same player reconnecting (phone woke up, page refreshed, second tab).
      // Detach the old socket first so its close() doesn't remove the player.
      peers.delete(existing.peer.id);
      existing.peer.close(4001, "replaced");
    }

    room.players.set(pid, {
      peer: peer,
      name: name,
      metadata: {}
    });
    peers.set(peer.id, { code, pid });
    send(peer, { type: "joined", id: pid, code });
    send(room.host, { type: "join", id: pid, name, rejoin: !!existing });
  },

  message(peer, raw) {
    const info = peers.get(peer.id);
    const room = info && rooms.get(info.code);
    if (!info || !room) return;

    let msg: any;
    try {
      msg = JSON.parse(raw.text());
    } catch {
      return;
    }

    if (info.pid === undefined) {
      // host -> player(s)
      if (msg?.to === "all") {
        for (const p of room.players.values()) send(p.peer, { type: "msg", data: msg.data });
      } else {
        const target = room.players.get(String(msg?.to));
        if (target) send(target.peer, { type: "msg", data: msg.data });
      }
    } else {
      // player -> host
      send(room.host, { type: "msg", from: info.pid, data: msg?.data ?? msg });
    }
  },

  close(peer) {
    const info = peers.get(peer.id);
    if (!info) return; // already detached (replaced socket)
    peers.delete(peer.id);
    const room = rooms.get(info.code);
    if (!room) return;

    if (info.pid === undefined) {
      for (const p of room.players.values()) {
        peers.delete(p.peer.id);
        send(p.peer, { type: "host_left" });
        p.peer.close(4002, "host_left");
      }
      rooms.delete(info.code);
    } else {
      room.players.delete(info.pid);
      send(room.host, { type: "leave", id: info.pid });
    }
  },
});
