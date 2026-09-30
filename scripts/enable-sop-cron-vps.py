#!/usr/bin/env python3
"""Build cron SQL from SOP_CRON_SECRET in the Edge Functions container. Do not print the secret."""
import json
import subprocess
from pathlib import Path

func = "supabase-edge-functions-c79x9r7qj8hyjitgl6mdkldz"
secret = subprocess.check_output(
    ["docker", "exec", func, "printenv", "SOP_CRON_SECRET"],
    text=True,
).strip()
if not secret:
    raise SystemExit("SOP_CRON_SECRET is empty")

headers = json.dumps(
    {
        "Content-Type": "application/json",
        "x-domio-cron-secret": secret,
    }
)

sql = f"""
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'generate-sop-tasks-nightly';

SELECT cron.schedule(
  'generate-sop-tasks-nightly',
  '5 0 * * *',
  $cronjob$SELECT net.http_post(
    url := 'https://db.j0zek.pl/functions/v1/generate-sop-tasks',
    headers := $hdrjson${headers}$hdrjson$::jsonb,
    body := '{{}}'::jsonb
  );$cronjob$
);
"""

out = Path("/tmp/enable-sop-cron.sql")
out.write_text(sql, encoding="utf-8")
print("wrote", out)
