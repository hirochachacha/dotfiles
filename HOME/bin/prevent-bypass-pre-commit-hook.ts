#!/usr/bin/env -S deno run

interface PreToolUseInput {
  tool_name: string;
  tool_input: {
    command?: string;
  }
}

async function main() {
  if (!Deno.stdin.isTerminal()) {
    const input = await new Response(Deno.stdin.readable).text();


    try {
      const json: PreToolUseInput = JSON.parse(input);

      const [command, ...args] = parseCommand(json.tool_input.command || "");

      if (command === "git") {
        if (args[0] === "commit" || args[0] === "push") {
          if (args.includes("--no-verify") || args.includes("-n")) {
            console.error("DO NOT BYPASS pre-commit hook");

            Deno.exit(2);
          }
        }
      }
    } catch {
      console.error("Error: Invalid JSON input");
      Deno.exit(1);
    }
  }
}

/**
 * POSIX Shell String Parser
 * Parses a shell command string into an array of arguments according to POSIX specifications
 * https://pubs.opengroup.org/onlinepubs/9799919799/
 */

export function parseCommand(input: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let i = 0;

  while (i < input.length) {
    const char = input[i];

    // Skip leading whitespace between tokens
    if (current === "" && isWhitespace(char)) {
      i++;
      continue;
    }

    // Handle single quotes
    if (char === "'") {
      i++; // Skip opening quote
      const start = i;

      // Find closing single quote
      while (i < input.length && input[i] !== "'") {
        i++;
      }

      if (i >= input.length) {
        throw new Error("Unterminated single quote");
      }

      // Add everything between quotes literally
      current += input.substring(start, i);
      i++; // Skip closing quote
      continue;
    }

    // Handle double quotes
    if (char === '"') {
      i++; // Skip opening quote

      while (i < input.length && input[i] !== '"') {
        if (input[i] === "\\" && i + 1 < input.length) {
          const next = input[i + 1];
          // In double quotes, backslash only escapes: $ ` " \ newline
          if (
            next === "$" || next === "`" || next === '"' || next === "\\" ||
            next === "\n"
          ) {
            i++; // Skip backslash
            current += input[i];
            i++;
          } else {
            // Backslash is literal before other characters
            current += input[i];
            i++;
          }
        } else {
          current += input[i];
          i++;
        }
      }

      if (i >= input.length) {
        throw new Error("Unterminated double quote");
      }

      i++; // Skip closing quote
      continue;
    }

    // Handle backslash outside quotes
    if (char === "\\" && i + 1 < input.length) {
      i++; // Skip backslash
      if (input[i] === "\n") {
        // Backslash-newline is line continuation - skip both
        i++;
        continue;
      }
      // Preserve literal value of next character
      current += input[i];
      i++;
      continue;
    }

    // Handle unquoted whitespace (token delimiter)
    if (isWhitespace(char)) {
      if (current !== "") {
        tokens.push(current);
        current = "";
      }
      i++;
      continue;
    }

    // Regular character
    current += char;
    i++;
  }

  // Add final token if any
  if (current !== "") {
    tokens.push(current);
  }

  return tokens;
}

function isWhitespace(char: string): boolean {
  return char === " " || char === "\t" || char === "\n" || char === "\r";
}

// Additional parser with support for advanced features
export function parseShellStringAdvanced(input: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let i = 0;

  while (i < input.length) {
    const char = input[i];

    // Skip leading whitespace
    if (current === "" && isWhitespace(char)) {
      i++;
      continue;
    }

    // Handle comments (# at start of word)
    if (current === "" && char === "#") {
      // Skip to end of line
      while (i < input.length && input[i] !== "\n") {
        i++;
      }
      continue;
    }

    // Handle single quotes
    if (char === "'") {
      const result = parseSingleQuoted(input, i);
      current += result.content;
      i = result.nextIndex;
      continue;
    }

    // Handle double quotes
    if (char === '"') {
      const result = parseDoubleQuoted(input, i);
      current += result.content;
      i = result.nextIndex;
      continue;
    }

    // Handle $'...' (ANSI-C quoting)
    if (char === "$" && i + 1 < input.length && input[i + 1] === "'") {
      const result = parseDollarQuoted(input, i);
      current += result.content;
      i = result.nextIndex;
      continue;
    }

    // Handle backslash
    if (char === "\\" && i + 1 < input.length) {
      i++; // Skip backslash
      if (input[i] === "\n") {
        // Line continuation
        i++;
        continue;
      }
      current += input[i];
      i++;
      continue;
    }

    // Handle whitespace (token delimiter)
    if (isWhitespace(char)) {
      if (current !== "") {
        tokens.push(current);
        current = "";
      }
      i++;
      continue;
    }

    // Regular character
    current += char;
    i++;
  }

  // Add final token
  if (current !== "") {
    tokens.push(current);
  }

  return tokens;
}

interface ParseResult {
  content: string;
  nextIndex: number;
}

function parseSingleQuoted(input: string, startIndex: number): ParseResult {
  let i = startIndex + 1; // Skip opening quote
  let content = "";

  while (i < input.length && input[i] !== "'") {
    content += input[i];
    i++;
  }

  if (i >= input.length) {
    throw new Error("Unterminated single quote");
  }

  return { content, nextIndex: i + 1 }; // Skip closing quote
}

function parseDoubleQuoted(input: string, startIndex: number): ParseResult {
  let i = startIndex + 1; // Skip opening quote
  let content = "";

  while (i < input.length && input[i] !== '"') {
    if (input[i] === "\\" && i + 1 < input.length) {
      const next = input[i + 1];
      // Special escape sequences in double quotes
      if (
        next === "$" || next === "`" || next === '"' || next === "\\" ||
        next === "\n"
      ) {
        i++; // Skip backslash
        if (next === "\n") {
          // Line continuation - skip newline
          i++;
          continue;
        }
        content += input[i];
        i++;
      } else {
        // Backslash is literal
        content += input[i];
        i++;
      }
    } else {
      content += input[i];
      i++;
    }
  }

  if (i >= input.length) {
    throw new Error("Unterminated double quote");
  }

  return { content, nextIndex: i + 1 }; // Skip closing quote
}

function parseDollarQuoted(input: string, startIndex: number): ParseResult {
  let i = startIndex + 2; // Skip $'
  let content = "";

  while (i < input.length && input[i] !== "'") {
    if (input[i] === "\\" && i + 1 < input.length) {
      i++; // Skip backslash
      const char = input[i];

      // ANSI-C escape sequences
      switch (char) {
        case "a":
          content += "\x07";
          break; // Alert (bell)
        case "b":
          content += "\b";
          break; // Backspace
        case "e":
          content += "\x1b";
          break; // Escape
        case "f":
          content += "\f";
          break; // Form feed
        case "n":
          content += "\n";
          break; // Newline
        case "r":
          content += "\r";
          break; // Carriage return
        case "t":
          content += "\t";
          break; // Tab
        case "v":
          content += "\v";
          break; // Vertical tab
        case "\\":
          content += "\\";
          break; // Backslash
        case "'":
          content += "'";
          break; // Single quote
        case '"':
          content += '"';
          break; // Double quote
        case "?":
          content += "?";
          break; // Question mark
        case "x": {
          // Hex escape \xHH
          if (
            i + 2 < input.length && isHexDigit(input[i + 1]) &&
            isHexDigit(input[i + 2])
          ) {
            const hex = input.substring(i + 1, i + 3);
            content += String.fromCharCode(parseInt(hex, 16));
            i += 2;
          } else {
            content += char;
          }
          break;
        }
        case "0":
        case "1":
        case "2":
        case "3":
        case "4":
        case "5":
        case "6":
        case "7": {
          // Octal escape \NNN
          let octal = char;
          let j = 1;
          while (j < 3 && i + j < input.length && isOctalDigit(input[i + j])) {
            octal += input[i + j];
            j++;
          }
          content += String.fromCharCode(parseInt(octal, 8));
          i += j - 1;
          break;
        }
        default:
          // Unknown escape - preserve literally
          content += char;
      }
      i++;
    } else {
      content += input[i];
      i++;
    }
  }

  if (i >= input.length) {
    throw new Error("Unterminated $' quote");
  }

  return { content, nextIndex: i + 1 }; // Skip closing quote
}

function isHexDigit(char: string): boolean {
  return /[0-9a-fA-F]/.test(char);
}

function isOctalDigit(char: string): boolean {
  return /[0-7]/.test(char);
}

if (import.meta.main) {
  main().catch((error) => {
    console.error(`Unexpected error: ${error.message}`);
    Deno.exit(1);
  });
}

