from __future__ import annotations

import html
from pathlib import Path


OUT = Path(__file__).resolve().parent / "lab-output"

STYLE = """
:root {
  color-scheme: dark;
  --bg: #10141b;
  --panel: #171d26;
  --line: #2c3644;
  --text: #e8edf3;
  --muted: #9eabb9;
  --green: #69d391;
  --blue: #73b7ff;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  min-height: 100vh;
  background: var(--bg);
  color: var(--text);
  font: 16px/1.6 "Microsoft YaHei", "Segoe UI", sans-serif;
}
main { width: min(1180px, 94vw); margin: 32px auto 48px; }
header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 20px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--line);
}
h1 { margin: 0; font-size: 26px; }
.meta { color: var(--muted); font-size: 14px; }
.command, .result {
  margin-top: 18px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
  overflow: hidden;
}
.label {
  padding: 9px 14px;
  border-bottom: 1px solid var(--line);
  color: var(--muted);
  font-size: 13px;
  letter-spacing: 0.04em;
}
pre {
  margin: 0;
  padding: 16px 18px 20px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  font: 14px/1.55 "Cascadia Mono", "Consolas", monospace;
}
.command pre { color: var(--blue); }
.result pre { color: var(--text); }
.result pre::selection { background: #315a7d; }
.footer { margin-top: 16px; color: var(--green); font-size: 13px; }
"""


def render_page(shot_id: str, title: str, command: str, output: str) -> str:
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
  <style>{STYLE}</style>
</head>
<body>
  <main>
    <header>
      <h1>{html.escape(title)}</h1>
      <div class="meta">GitHub Codespaces 实际执行记录 · 截图 {html.escape(shot_id)}</div>
    </header>
    <section class="command">
      <div class="label">COMMAND</div>
      <pre>{html.escape(command.strip())}</pre>
    </section>
    <section class="result">
      <div class="label">REAL OUTPUT</div>
      <pre>{html.escape(output.strip())}</pre>
    </section>
    <div class="footer">云主机容器内实际命令输出，未使用示例结果代替。</div>
  </main>
</body>
</html>
"""


def main() -> None:
    manifest = OUT / "manifest.tsv"
    if not manifest.exists():
        raise SystemExit("manifest.tsv not found")

    for line in manifest.read_text(encoding="utf-8").splitlines():
        shot_id, title, command_path, output_path = line.split("\t", 3)
        command = Path(command_path).read_text(encoding="utf-8")
        output = Path(output_path).read_text(encoding="utf-8")
        (OUT / f"shot{shot_id}.html").write_text(
            render_page(shot_id, title, command, output),
            encoding="utf-8",
        )

    index_links = "\n".join(
        f'<li><a href="shot{line.split(chr(9), 1)[0]}.html">'
        f'{html.escape(line.split(chr(9), 2)[1])}</a></li>'
        for line in manifest.read_text(encoding="utf-8").splitlines()
    )
    (OUT / "index.html").write_text(
        f"""<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<title>云计算实验实际执行记录</title><style>{STYLE}</style></head>
<body><main><header><h1>云计算实验实际执行记录</h1>
<div class="meta">12 个真实命令结果页面</div></header>
<ul>{index_links}</ul></main></body></html>""",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
