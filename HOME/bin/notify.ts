#!/usr/bin/env -S deno run --allow-env --allow-net --allow-read

import { load } from "jsr:@std/dotenv";

const HOME = Deno.env.get("HOME");

if (!HOME) {
  throw new Error("Error: HOME environment variable is not set");
}

const { NTFY_AGENT_TOPIC } = await load({ envPath: `${HOME}/.env` });

if (!NTFY_AGENT_TOPIC) {
  throw new Error("Error: NTFY_AGENT_TOPIC environment variable is not set");
}

interface NotificationInput {
  title: string;
  message: string;
}

async function main() {
  let title: string | undefined;
  let message: string | undefined;

  if (Deno.args.length === 2) {
    title = Deno.args[0];
    message = Deno.args[1];
    if (!message) {
      const thisPath = new URL(import.meta.url).pathname;
      console.error(`Usage: ${thisPath} <title> <message>`);
      console.error(
        `   or: echo '{"title": "mytitle", "message": "mymessage"}' | ${thisPath}`,
      );
      Deno.exit(1);
    }
  } else if (!Deno.stdin.isTerminal()) {
    const input = await new Response(Deno.stdin.readable).text();
    try {
      const json: NotificationInput = JSON.parse(input);
      title = json.title || "Claude";
      message = json.message;
    } catch {
      console.error("Error: Invalid JSON input");
      Deno.exit(1);
    }
  }

  if (message) {
    await fetch(`https://ntfy.sh/${NTFY_AGENT_TOPIC}`, {
      method: "POST", // PUT works too
      body: message,
      headers: {
        "Title": title,
      },
    });
  } else {
    console.error("Error: No message provided");
    Deno.exit(1);
  }
}

if (import.meta.main) {
  main().catch((error) => {
    console.error(`Unexpected error: ${error.message}`);
    Deno.exit(1);
  });
}
