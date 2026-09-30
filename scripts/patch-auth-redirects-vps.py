#!/usr/bin/env python3
"""Append missing Auth redirect origins to Coolify ADDITIONAL_REDIRECT_URLS. No secrets."""
from pathlib import Path

env_path = Path("/data/coolify/services/c79x9r7qj8hyjitgl6mdkldz/.env")
extra = [
    "https://test.home.domio.com.pl",
    "https://test.home.domio.com.pl/**",
    "https://test.admin.domio.com.pl",
    "https://test.admin.domio.com.pl/**",
    "https://adm.domio.com.pl",
    "https://adm.domio.com.pl/**",
    "https://test.adm.domio.com.pl",
    "https://test.adm.domio.com.pl/**",
]

lines = env_path.read_text(encoding="utf-8").splitlines(keepends=True)
out = []
found = False
for line in lines:
    if line.startswith("ADDITIONAL_REDIRECT_URLS="):
        found = True
        prefix, _, rest = line.partition("=")
        rest = rest.rstrip("\n")
        parts = [p.strip() for p in rest.split(",") if p.strip()]
        for item in extra:
            if item not in parts:
                parts.append(item)
        out.append(prefix + "=" + ",".join(parts) + "\n")
    else:
        out.append(line)
if not found:
    raise SystemExit("ADDITIONAL_REDIRECT_URLS not found")
env_path.write_text("".join(out), encoding="utf-8")
print("updated ADDITIONAL_REDIRECT_URLS, count", len(parts))
