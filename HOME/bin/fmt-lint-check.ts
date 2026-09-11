#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run

const USE_EXIT_CODE = false

interface ToolInput {
  tool_input?: { file_path?: string };
  tool_response?: { filePath?: string };
}

const FORMATTERS: Record<string, string[][]> = {
  "ts,tsx,js,jsx": [
    ["deno", "fmt", "$FILE"],
    ["deno", "lint", "--fix", "$FILE"],
    ["deno", "check", "$FILE"],
  ],
  "rs": [
    ["rustfmt", "$FILE"],
    ["cargo", "clippy", "--fix", "--allow-dirty", "--allow-staged"],
  ],
  "py": [
    ["ruff", "format", "$FILE"],
    ["ruff", "check", "--fix", "$FILE"],
  ],
  "go": [
    ["gofmt", "-w", "$FILE"],
    ["golangci-lint", "run", "--fix", "$FILE"],
  ],
  "java": [["google-java-format", "-i", "$FILE"]],
  "cpp,cc,c,h,hpp": [["clang-format", "-i", "$FILE"]],
  "rb": [["rubocop", "-a", "$FILE"]],
  "php": [["php-cs-fixer", "fix", "$FILE"]],
  "swift": [["swiftformat", "$FILE"]],
  "kt,kts": [["ktlint", "-F", "$FILE"]],
  "scala": [["scalafmt", "$FILE"]],
  "ex,exs": [["mix", "format", "$FILE"]],
  "clj,cljs,cljc": [["cljfmt", "fix", "$FILE"]],
  "hs": [["ormolu", "-i", "$FILE"]],
  "ml,mli": [["ocamlformat", "-i", "$FILE"]],
  "nim": [["nimpretty", "$FILE"]],
  "zig": [["zig", "fmt", "$FILE"]],
  "dart": [["dart", "format", "$FILE"]],
  "lua": [["stylua", "$FILE"]],
  "jl": [["julia", "-e", 'using JuliaFormatter; format_file("$FILE")']],
  "r,R": [["Rscript", "-e", "styler::style_file('$FILE')"]],
  "cs": [["dotnet", "format", "--include", "$FILE"]],
  "fs,fsx,fsi": [["fantomas", "$FILE"]],
  "json": [["deno", "fmt", "$FILE"]],
  "xml": [["xmllint", "--format", "$FILE", "-o", "$FILE"]],
  "yaml,yml": [["deno", "fmt", "--unstable-component", "$FILE"]],
  "toml": [["taplo", "fmt", "$FILE"]],
  "md": [["deno", "fmt", "$FILE"]],
  "css,scss,sass,less": [["deno", "fmt", "--unstable-component", "$FILE"]],
  "html,htm": [["deno", "fmt", "--unstable-component", "$FILE"]],
  "vue": [["deno", "fmt", "--unstable-component", "$FILE"]],
  "svelte": [["deno", "fmt", "--unstable-component", "$FILE"]],
};

async function runCommand(cmd: string[]) {
  try {
    const process = new Deno.Command(cmd[0], {
      args: cmd.slice(1),
      stdout: "piped",
      stderr: "piped",
    });

    const { code, stdout, stderr } = await process.output();
    return {
      success: code === 0,
      code,
      stdout: new TextDecoder().decode(stdout),
      stderr: new TextDecoder().decode(stderr),
    };
  } catch (error) {
    return {
      success: false,
      code: -1,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

async function main() {
  let filePath = Deno.args[0];

  if (!filePath && !Deno.stdin.isTerminal()) {
    try {
      const input = await new Response(Deno.stdin.readable).text();
      const json: ToolInput = JSON.parse(input);
      filePath = json.tool_input?.file_path || json.tool_response?.filePath;
    } catch { /* ignore */ }
  }

  if (!filePath) {
    console.error("Error: No file path provided.");
    Deno.exit(1);
  }

  let originalStat, originalContent;
  try {
    originalStat = await Deno.stat(filePath);
    originalContent = await Deno.readTextFile(filePath);
  } catch (error) {
    console.error(`Error reading file: ${filePath}`, error);
    Deno.exit(1);
  }

  const ext = filePath.split(".").pop()?.toLowerCase() || "";
  const entry = Object.entries(FORMATTERS).find(([exts]) =>
    exts.split(",").includes(ext)
  );

  if (!entry) {
    console.warn(`No formatter configured for: ${filePath}`);
    return;
  }

  const errors = [];
  for (const rawCmd of entry[1]) {
    const cmd = rawCmd.map((arg) => arg.replace("$FILE", filePath));
    const result = await runCommand(cmd);

    // Stop and report error if tool failed (ignore if tool not found)
    if (!result.success && result.code !== -1) {
      errors.push({ command: cmd, ...result });
      break;
    }
  }

  if (errors.length > 0) {
    if (USE_EXIT_CODE) {
      console.error(errors)
      Deno.exit(2);
    } else {
      console.log(JSON.stringify(
        {
          suppressOutput: true,
          decision: "block",
          reason: errors,
        },
        null,
        2,
      ));
      Deno.exit(0);
    }
  }

  const newContent = await Deno.readTextFile(filePath);
  const newStat = await Deno.stat(filePath);

  if (
    originalContent !== newContent ||
    originalStat.mtime?.getTime() !== newStat.mtime?.getTime()
  ) {
    if (USE_EXIT_CODE) {
      console.error(`${filePath} was modified by formatter`)
      Deno.exit(2);
    } else {
      console.log(JSON.stringify(
        {
          suppressOutput: true,
          decision: "block",
          reason: `${filePath} was modified by formatter`,
        },
        null,
        2,
      ));
      Deno.exit(0);
    }
  }
}

if (import.meta.main) {
  main().catch((error) => {
    console.error("Unexpected error:", error);
    Deno.exit(1);
  });
}
