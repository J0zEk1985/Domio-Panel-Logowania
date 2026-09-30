#!/usr/bin/env python3
"""Set GUS test key and copy Gemini API key from n8n. Never print secrets."""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

STACK_ENV = Path("/data/coolify/services/c79x9r7qj8hyjitgl6mdkldz/.env")
N8N_CONFIG = Path("/var/lib/docker/volumes/oq0frjy2l93d75uu1l2736ms_n8n-data/_data/config")
GUS_TEST = "abcde12345abcde12345"
N8N_CTR = "n8n-oq0frjy2l93d75uu1l2736ms"
PG_CTR = "postgresql-oq0frjy2l93d75uu1l2736ms"


def docker_env(container: str, key: str) -> str:
    return subprocess.check_output(["docker", "exec", container, "printenv", key], text=True).strip()


def fetch_palm_blob() -> str:
    user = docker_env(N8N_CTR, "DB_POSTGRESDB_USER")
    password = docker_env(N8N_CTR, "DB_POSTGRESDB_PASSWORD")
    sql = "SELECT data FROM credentials_entity WHERE type = 'googlePalmApi' LIMIT 1;"
    proc = subprocess.run(
        [
            "docker",
            "exec",
            "-e",
            f"PGPASSWORD={password}",
            PG_CTR,
            "psql",
            "-U",
            user,
            "-d",
            "n8n",
            "-tA",
            "-c",
            sql,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    blob = proc.stdout.strip()
    if not blob:
        raise SystemExit("no googlePalmApi credential in n8n-test")
    return blob


def decrypt_with_n8n_node(encrypted_b64: str, encryption_key: str) -> str:
    work = Path("/tmp/n8n-gemini-decrypt")
    work.mkdir(mode=0o700, exist_ok=True)
    (work / "enc.b64").write_text(encrypted_b64, encoding="utf-8")
    (work / "key.txt").write_text(encryption_key, encoding="utf-8")
    js = r"""
const fs = require('fs');
const crypto = require('crypto');
const enc = fs.readFileSync('/work/enc.b64', 'utf8').trim();
const encryptionKey = fs.readFileSync('/work/key.txt', 'utf8');
const key = crypto.createHash('sha256').update(encryptionKey).digest();
const buf = Buffer.from(enc, 'base64');
const iv = buf.subarray(0, 16);
const data = buf.subarray(16);
const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
const out = Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
fs.writeFileSync('/work/plain.json', out);
"""
    (work / "decrypt.js").write_text(js, encoding="utf-8")
    subprocess.run(
        [
            "docker",
            "exec",
            "-v",
            f"{work}:/work",
            N8N_CTR,
            "node",
            "/work/decrypt.js",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    # docker exec -v may not work; copy files into container instead
    return (work / "plain.json").read_text(encoding="utf-8")


def decrypt_copy_into_container(encrypted_b64: str, encryption_key: str) -> str:
    work = Path("/tmp/n8n-gemini-decrypt")
    work.mkdir(mode=0o700, exist_ok=True)
    (work / "enc.b64").write_text(encrypted_b64, encoding="utf-8")
    (work / "key.txt").write_text(encryption_key, encoding="utf-8")
    (work / "decrypt.js").write_text(
        r"""
const fs = require('fs');
const crypto = require('crypto');
const enc = fs.readFileSync('/tmp/enc.b64', 'utf8').trim();
const encryptionKey = fs.readFileSync('/tmp/key.txt', 'utf8');
const input = Buffer.from(enc, 'base64');
const salt = input.subarray(8, 16);
const password = Buffer.concat([Buffer.from(encryptionKey, 'binary'), salt]);
const hash1 = crypto.createHash('md5').update(password).digest();
const hash2 = crypto.createHash('md5').update(Buffer.concat([hash1, password])).digest();
const iv = crypto.createHash('md5').update(Buffer.concat([hash2, password])).digest();
const key = Buffer.concat([hash1, hash2]);
const contents = input.subarray(16);
const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
const out = Buffer.concat([decipher.update(contents), decipher.final()]).toString('utf8');
fs.writeFileSync('/tmp/plain.json', out);
""",
        encoding="utf-8",
    )
    subprocess.run(["docker", "cp", str(work / "enc.b64"), f"{N8N_CTR}:/tmp/enc.b64"], check=True)
    subprocess.run(["docker", "cp", str(work / "key.txt"), f"{N8N_CTR}:/tmp/key.txt"], check=True)
    subprocess.run(["docker", "cp", str(work / "decrypt.js"), f"{N8N_CTR}:/tmp/decrypt.js"], check=True)
    subprocess.run(["docker", "exec", N8N_CTR, "node", "/tmp/decrypt.js"], check=True, capture_output=True, text=True)
    subprocess.run(["docker", "cp", f"{N8N_CTR}:/tmp/plain.json", str(work / "plain.json")], check=True)
    subprocess.run(
        ["docker", "exec", N8N_CTR, "rm", "-f", "/tmp/enc.b64", "/tmp/key.txt", "/tmp/decrypt.js", "/tmp/plain.json"],
        check=False,
    )
    plain = (work / "plain.json").read_text(encoding="utf-8")
    for p in work.iterdir():
        p.unlink()
    work.rmdir()
    return plain


def extract_api_key(plain: str) -> str:
    obj = json.loads(plain)
    for k in ("apiKey", "api_key", "key"):
        val = obj.get(k)
        if isinstance(val, str) and val.strip():
            return val.strip()
    raise SystemExit("gemini json missing apiKey, keys=" + ",".join(sorted(obj.keys())))


def upsert(lines: list[str], key: str, value: str) -> list[str]:
    prefix = key + "="
    out: list[str] = []
    found = False
    for line in lines:
        raw = line.rstrip("\n")
        if raw.startswith(prefix):
            out.append(f"{key}={value}\n")
            found = True
        else:
            out.append(line if line.endswith("\n") else line + "\n")
    if not found:
        out.append(f"{key}={value}\n")
    return out


def main() -> None:
    enc_key = json.loads(N8N_CONFIG.read_text(encoding="utf-8"))["encryptionKey"]
    blob = fetch_palm_blob()
    try:
        wrapper = json.loads(blob)
        encrypted = wrapper["data"] if isinstance(wrapper, dict) and "data" in wrapper else blob
    except json.JSONDecodeError:
        encrypted = blob
    if isinstance(encrypted, dict):
        encrypted = encrypted.get("data") or json.dumps(encrypted)
    plain = decrypt_copy_into_container(str(encrypted), enc_key)
    gemini = extract_api_key(plain)

    lines = STACK_ENV.read_text(encoding="utf-8").splitlines(keepends=True)
    lines = upsert(lines, "GUS_BIR_KEY", GUS_TEST)
    lines = upsert(lines, "GUS_BIR_ENV", "test")
    lines = upsert(lines, "GEMINI_API_KEY", gemini)
    STACK_ENV.write_text("".join(lines), encoding="utf-8")
    print("updated GUS_BIR_KEY GUS_BIR_ENV GEMINI_API_KEY")
    print("gemini_from n8n-test googlePalmApi")


if __name__ == "__main__":
    main()
