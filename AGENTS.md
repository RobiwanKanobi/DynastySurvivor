# AGENTS.md

## Cursor Cloud specific instructions

This is a **Godot 4.6 game project** ("Ant Hill" idle/simulation game) written in GDScript. There are no package managers, Docker containers, databases, or backend services.

### Engine

- Requires **Godot Engine 4.6.1** (`/usr/local/bin/godot`). The update script installs it automatically from GitHub releases.

### Project structure

| Path | Purpose |
|---|---|
| `project.godot` | Godot project config; main scene is `ant_hill/ant_hill_game.tscn` |
| `ant_hill/` | All game scenes and GDScript source files |
| `addons/gdai-mcp-plugin-godot/` | GDAI MCP editor plugin (optional; binary not included — gracefully no-ops) |
| `Builds/` | Web export output directory |
| `export_presets.cfg` | Godot export preset for Web |

### Running the game

- **Native (with display):** `godot --path /workspace` opens the editor; press F5 / Play to run.
- **Headless import:** `godot --headless --import` imports all resources without a display.
- **Web export:** `godot --headless --export-release "Web"` builds to `Builds/`. Serve with COOP/COEP headers:
  ```
  python3 -c "
  from http.server import HTTPServer, SimpleHTTPRequestHandler
  class H(SimpleHTTPRequestHandler):
      def end_headers(self):
          self.send_header('Cross-Origin-Opener-Policy','same-origin')
          self.send_header('Cross-Origin-Embedder-Policy','require-corp')
          super().end_headers()
  HTTPServer(('0.0.0.0',8080),H).serve_forever()
  "
  ```
  Then open `http://localhost:8080/index.html` in Chrome.

### Linting / validation

- GDScript syntax check: `godot --headless --check-only --script <file.gd>`
- Validate all game scripts: `for f in ant_hill/*.gd; do godot --headless --check-only --script "$f"; done`

### Gotchas

- Export templates must be installed at `~/.local/share/godot/export_templates/4.6.1.stable/` before web export will work. The update script handles this.
- The GDAI MCP plugin prints a warning about missing binaries on every editor/export run — this is harmless.
- The web export requires COOP/COEP headers; a plain `python3 -m http.server` will not work.
