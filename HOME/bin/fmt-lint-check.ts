#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run

interface ToolInput {
  tool_input?: { file_path?: string };
  tool_response?: { filePath?: string };
}

const formatters: Record<string, (file: string) => Promise<void>> = {
  // TypeScript/JavaScript
  "ts,tsx,js,jsx": async (file) => {
    await runCommand(["deno", "fmt", file]);
    await runCommand(["deno", "lint", "--fix", file]);
    await runCommand(["deno", "check", file], true);
  },

  // Rust
  "rs": async (file) => {
    await runCommand(["rustfmt", file]);
    await runCommand([
      "cargo",
      "clippy",
      "--fix",
      "--allow-dirty",
      "--allow-staged",
    ], true);
  },

  // Python
  "py": async (file) => {
    await runCommand(["black", file]);
    await runCommand(["ruff", "check", "--fix", file]);
    await runCommand(["mypy", file], true);
  },

  // Go
  "go": async (file) => {
    await runCommand(["gofmt", "-w", file]);
    await runCommand(["golangci-lint", "run", "--fix", file], true);
  },

  // Java
  "java": async (file) => {
    await runCommand(["google-java-format", "-i", file], true);
  },

  // C/C++
  "cpp,cc,c,h,hpp": async (file) => {
    await runCommand(["clang-format", "-i", file], true);
  },

  // Ruby
  "rb": async (file) => {
    await runCommand(["rubocop", "-a", file], true);
  },

  // PHP
  "php": async (file) => {
    await runCommand(["php-cs-fixer", "fix", file], true);
  },

  // Swift
  "swift": async (file) => {
    await runCommand(["swiftformat", file], true);
  },

  // Kotlin
  "kt,kts": async (file) => {
    await runCommand(["ktlint", "-F", file], true);
  },

  // Scala
  "scala": async (file) => {
    await runCommand(["scalafmt", file], true);
  },

  // Elixir
  "ex,exs": async (file) => {
    await runCommand(["mix", "format", file], true);
  },

  // Clojure
  "clj,cljs,cljc": async (file) => {
    await runCommand(["cljfmt", "fix", file], true);
  },

  // Haskell
  "hs": async (file) => {
    await runCommand(["ormolu", "-i", file], true);
  },

  // OCaml
  "ml,mli": async (file) => {
    await runCommand(["ocamlformat", "-i", file], true);
  },

  // Nim
  "nim": async (file) => {
    await runCommand(["nimpretty", file], true);
  },

  // Zig
  "zig": async (file) => {
    await runCommand(["zig", "fmt", file], true);
  },

  // Dart
  "dart": async (file) => {
    await runCommand(["dart", "format", file], true);
  },

  // Lua
  "lua": async (file) => {
    await runCommand(["stylua", file], true);
  },

  // Julia
  "jl": async (file) => {
    await runCommand([
      "julia",
      "-e",
      `using JuliaFormatter; format_file("${file}")`,
    ], true);
  },

  // R
  "r,R": async (file) => {
    await runCommand(["Rscript", "-e", `styler::style_file('${file}')`], true);
  },

  // C#
  "cs": async (file) => {
    await runCommand(["dotnet", "format", "--include", file], true);
  },

  // F#
  "fs,fsx,fsi": async (file) => {
    await runCommand(["fantomas", file], true);
  },

  // JSON
  "json": async (file) => {
    await runCommand(["deno", "fmt", file]);
    // const content = await Deno.readTextFile(file);
    // const formatted = JSON.stringify(JSON.parse(content), null, 2);
    // await Deno.writeTextFile(file, formatted);
  },

  // XML
  "xml": async (file) => {
    await runCommand(["xmllint", "--format", file, "-o", file], true);
  },

  // YAML
  "yaml,yml": async (file) => {
    await runCommand(["deno", "fmt", "--unstable-component", file]);
    // await runCommand(["yamllint", "-d", "relaxed", file], true);
  },

  // TOML
  "toml": async (file) => {
    await runCommand(["taplo", "fmt", file], true);
  },

  // Markdown
  "md": async (file) => {
    await runCommand(["deno", "fmt", file]);
    // await runCommand(["markdownlint", "--fix", file], true);
  },

  // CSS and preprocessors
  "css,scss,sass,less": async (file) => {
    await runCommand(["deno", "fmt", "--unstable-component", file]);
    // await runCommand(["prettier", "--write", file], true);
  },

  // HTML
  "html,htm": async (file) => {
    await runCommand(["deno", "fmt", "--unstable-component", file]);
    // await runCommand(["prettier", "--write", file], true);
  },

  // Vue
  "vue": async (file) => {
    await runCommand(["deno", "fmt", "--unstable-component", file]);
    // await runCommand(["prettier", "--write", file]);
    // await runCommand(["eslint", "--fix", file], true);
  },

  // Svelte
  "svelte": async (file) => {
    await runCommand(["deno", "fmt", "--unstable-component", file]);
    // await runCommand([
    //   "prettier",
    //   "--write",
    //   "--plugin",
    //   "prettier-plugin-svelte",
    //   file,
    // ], true);
  },
};

async function runCommand(
  cmd: string[],
  ignoreError = false,
): Promise<{ success: boolean; stderr?: string }> {
  try {
    const command = new Deno.Command(cmd[0], {
      args: cmd.slice(1),
      stdout: "piped",
      stderr: "piped",
    });

    const { code, stderr } = await command.output();
    const errorText = new TextDecoder().decode(stderr);

    if (code !== 0) {
      if (!ignoreError) {
        console.error(`Error running ${cmd[0]}: ${errorText}`);
        hasErrors = true;
      }
      return { success: false, stderr: errorText };
    }
    return { success: true, stderr: errorText };
  } catch (error) {
    if (!ignoreError) {
      console.error(`Failed to run ${cmd[0]}: ${error.message}`);
      hasErrors = true;
    }
    return { success: false };
  }
}

function findFormatter(
  filePath: string,
): ((file: string) => Promise<void>) | null {
  const ext = filePath.split(".").pop()?.toLowerCase();
  if (!ext) return null;

  for (const [extensions, formatter] of Object.entries(formatters)) {
    if (extensions.split(",").includes(ext)) {
      return formatter;
    }
  }
  return null;
}

// Track if any files were modified or if any errors occurred
let filesModified = false;
let hasErrors = false;

async function formatFile(filePath: string): Promise<void> {
  let originalStat;
  try {
    originalStat = await Deno.stat(filePath);
  } catch {
    console.error(`Error: File '${filePath}' not found`);
    Deno.exit(1);
  }

  // Get original content to detect changes
  const originalContent = await Deno.readTextFile(filePath);

  const formatter = findFormatter(filePath);
  if (formatter) {
    await formatter(filePath);

    // Check if file was modified
    const newContent = await Deno.readTextFile(filePath);
    const newStat = await Deno.stat(filePath);

    if (
      originalContent !== newContent ||
      originalStat.mtime?.getTime() !== newStat.mtime?.getTime()
    ) {
      filesModified = true;
      console.log(`Formatted: ${filePath}`);
    }
  } else {
    console.warn(`Warning: No formatter configured for file type: ${filePath}`);
  }
}

async function main() {
  if (Deno.args.length > 0) {
    for (const file of Deno.args) {
      await formatFile(file);
    }
  } else if (!Deno.stdin.isTerminal()) {
    const input = await new Response(Deno.stdin.readable).text();
    try {
      const json: ToolInput = JSON.parse(input);
      const file = json.tool_input?.file_path || json.tool_response?.filePath;
      if (!file) {
        console.error("Error: No file path found in JSON input");
        Deno.exit(1);
      }
      await formatFile(file);
    } catch (error) {
      console.error("Error: Invalid JSON input", error);
      Deno.exit(1);
    }
  } else {
    console.error("No input provided. Specify files or pipe JSON to stdin.");
    Deno.exit(1);
  }
}

if (import.meta.main) {
  main().then(() => {
    // Exit with code 2 if files were modified or if there were any errors (for Claude Code hooks)
    if (filesModified || hasErrors) {
      Deno.exit(2);
    }
  }).catch((error) => {
    console.error(`Unexpected error: ${error.message}`);
    Deno.exit(1);
  });
}
