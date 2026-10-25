"""Bounded-space Docker release export, validation, and public asset mirroring."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from typing import BinaryIO, Callable


PART_BYTES = 1024**3
ASSET_LIMIT = 2 * 1024**3
BLOCK_BYTES = 1024**2
NATIVE_ASSETS = {
    "FinAgent-macOS.dmg",
    "FinAgent-Windows-x64.exe",
    "FinAgent-Linux-x86_64.tar.gz",
    "FinAgent-Linux-arm64.tar.gz",
}
HELPERS = {"docker_up.sh", "docker-compose.yml", "load_docker_release.sh"}


def gh(*args: str, env: dict[str, str] | None = None) -> str:
    return subprocess.check_output(["gh", *args], env=env, text=True)


def release(repo: str, tag: str, env: dict[str, str] | None = None) -> dict:
    return json.loads(gh("release", "view", tag, "--repo", repo,
                         "--json", "isDraft,assets", env=env))


def archive_name(arch: str) -> str:
    return f"FinAgent-Docker-{arch}.tar.gz"


def manifest_parts(text: str, archive: str) -> dict[str, str]:
    parts: dict[str, str] = {}
    for number, line in enumerate(text.splitlines(), 1):
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        expected = f"{archive}.part-{number:06d}"
        if not match or match[2] != expected:
            raise ValueError(f"Invalid or out-of-order manifest entry: {line!r}")
        parts[expected] = match[1]
    if not parts:
        raise ValueError(f"Empty manifest for {archive}")
    return parts


def upload_parts(
    stream: BinaryIO,
    archive: str,
    directory: Path,
    upload: Callable[[Path], None],
    part_bytes: int = PART_BYTES,
) -> dict[str, str]:
    if not 0 < part_bytes < ASSET_LIMIT:
        raise ValueError("Part size must be positive and below GitHub's 2 GiB limit")
    parts: dict[str, str] = {}
    while block := stream.read(min(BLOCK_BYTES, part_bytes)):
        name = f"{archive}.part-{len(parts) + 1:06d}"
        path = directory / name
        digest = hashlib.sha256()
        size = 0
        try:
            with path.open("wb") as output:
                while block:
                    output.write(block)
                    digest.update(block)
                    size += len(block)
                    if size == part_bytes:
                        break
                    block = stream.read(min(BLOCK_BYTES, part_bytes - size))
            print(f"Uploading {name} ({size} bytes)", flush=True)
            upload(path)
            parts[name] = digest.hexdigest()
        finally:
            path.unlink(missing_ok=True)
    if not parts:
        raise ValueError("Docker export produced no data")
    return parts


def stop_process(process: subprocess.Popen) -> None:
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def upload_docker(repo: str, tag: str, arch: str, images: list[str]) -> None:
    current = release(repo, tag)
    if not current["isDraft"]:
        raise ValueError("Docker assets may only be replaced on a draft release")
    archive = archive_name(arch)
    manifest = f"{archive}.sha256"
    old_names = [asset["name"] for asset in current["assets"]
                 if asset["name"] in (archive, manifest)
                 or asset["name"].startswith(f"{archive}.part-")]
    def upload(path: Path) -> None:
        gh("release", "upload", tag, str(path), "--repo", repo, "--clobber")

    with tempfile.TemporaryDirectory(prefix="finagent-release-") as temporary:
        directory = Path(temporary)
        if shutil.disk_usage(directory).free < PART_BYTES + 1024**3:
            raise OSError("Need at least 2 GiB free for a 1 GiB part and export headroom")
        # Remove the completion marker first; a failed retry must not look complete.
        for name in sorted(old_names, key=lambda name: name != manifest):
            gh("release", "delete-asset", tag, name, "--repo", repo, "--yes")
        producer = subprocess.Popen(["docker", "save", *images], stdout=subprocess.PIPE)
        try:
            assert producer.stdout is not None
            compressor = subprocess.Popen(
                ["gzip", "-n"], stdin=producer.stdout, stdout=subprocess.PIPE,
            )
            producer.stdout.close()
            try:
                assert compressor.stdout is not None
                with compressor.stdout:
                    parts = upload_parts(compressor.stdout, archive, directory, upload)
                for command, process in (("gzip", compressor), ("docker save", producer)):
                    if process.wait() != 0:
                        raise RuntimeError(f"{command} failed; completion manifest not uploaded")
            finally:
                stop_process(compressor)
        finally:
            stop_process(producer)
        path = directory / manifest
        path.write_text("".join(f"{digest}  {name}\n" for name, digest in parts.items()))
        upload(path)
        print(f"Completed {archive}: {len(parts)} parts and checksum manifest", flush=True)


def verify_release(
    repo: str, tag: str, env: dict[str, str] | None = None,
) -> tuple[dict, dict[str, str]]:
    current = release(repo, tag, env)
    assets = {asset["name"]: asset for asset in current["assets"]}
    missing = NATIVE_ASSETS - assets.keys()
    if missing:
        raise ValueError(f"Missing native assets: {sorted(missing)}")
    checksums: dict[str, str] = {}
    for arch in ("x86_64", "arm64"):
        archive = archive_name(arch)
        manifest = f"{archive}.sha256"
        names = {name for name in assets if name.startswith(f"{archive}.part-")}
        if manifest not in assets:
            if archive in assets and not names:
                continue  # Older releases use a single Docker archive.
            raise ValueError(f"Missing completion manifest: {manifest}")
        if archive in assets or assets[manifest]["size"] > 128 * 1024:
            raise ValueError(f"Invalid or ambiguous Docker assets for {arch}")
        text = gh("release", "download", tag, "--repo", repo,
                  "--pattern", manifest, "--output", "-", env=env)
        parts = manifest_parts(text, archive)
        if names != parts.keys():
            raise ValueError(f"Missing or unexpected parts for {archive}")
        for name in parts:
            if not 0 < assets[name]["size"] <= PART_BYTES:
                raise ValueError(f"Invalid part size: {name}")
        checksums.update(parts)
    for name, asset in assets.items():
        if name.startswith("FinAgent-") or name in HELPERS:
            if asset["state"] != "uploaded" or not 0 < asset["size"] < ASSET_LIMIT:
                raise ValueError(f"Incomplete or oversized release asset: {name}")
    return current, checksums


def mirror(source_repo: str, target_repo: str, tag: str, notes: str) -> None:
    source_env = dict(os.environ, GH_TOKEN=os.environ["SOURCE_GH_TOKEN"])
    source, checksums = verify_release(source_repo, tag, source_env)
    if source["isDraft"]:
        raise ValueError("Private release must be manually published before mirroring")
    source_assets = {asset["name"]: asset for asset in source["assets"]
                     if asset["name"].startswith("FinAgent-")}
    if checksums and not any(asset["name"] == "load_docker_release.sh" for asset in source["assets"]):
        raise ValueError("Multipart release is missing load_docker_release.sh")
    # The public launchers intentionally do not contain the private Compose build configuration.
    helpers = [Path(notes).resolve().parent / name for name in sorted(HELPERS)]
    for path in helpers:
        if not path.is_file() or not 0 < path.stat().st_size < ASSET_LIMIT:
            raise ValueError(f"Missing or invalid public helper: {path}")
    pages = json.loads(gh("api", "--paginate", "--slurp", f"repos/{target_repo}/releases"))
    existing = next((item for page in pages for item in page if item["tag_name"] == tag), None)
    if existing:
        if not existing["draft"]:
            public, public_checksums = verify_release(target_repo, tag)
            expected_sizes = {name: asset["size"] for name, asset in source_assets.items()}
            expected_sizes.update({path.name: path.stat().st_size for path in helpers})
            actual_sizes = {asset["name"]: asset["size"] for asset in public["assets"]
                            if asset["name"].startswith("FinAgent-") or asset["name"] in HELPERS}
            if expected_sizes != actual_sizes or checksums != public_checksums:
                raise ValueError(f"{tag} is already public with different assets; use a new version")
            print(f"{tag} is already published and complete")
            return
        for asset in existing["assets"]:
            name = asset["name"]
            if name.startswith("FinAgent-") or name in HELPERS:
                gh("release", "delete-asset", tag, name, "--repo", target_repo, "--yes")
        gh("release", "edit", tag, "--repo", target_repo, "--notes-file", notes)
    else:
        gh("release", "create", tag, "--repo", target_repo, "--draft",
           "--title", f"FinAgent {tag}", "--notes-file", notes)
    with tempfile.TemporaryDirectory(prefix="finagent-mirror-") as temporary:
        directory = Path(temporary)
        for name in sorted(source_assets, key=lambda name: (name.endswith(".sha256"), name)):
            if Path(name).name != name or name in (".", "..") or "\\" in name:
                raise ValueError(f"Unsafe asset filename: {name!r}")
            path = directory / name
            print(f"Mirroring {name}", flush=True)
            gh("release", "download", tag, "--repo", source_repo,
               "--pattern", name, "--dir", str(directory), env=source_env)
            if path.stat().st_size != source_assets[name]["size"]:
                raise ValueError(f"Download size mismatch: {name}")
            if name in checksums:
                with path.open("rb") as part:
                    digest = hashlib.file_digest(part, "sha256").hexdigest()
                if digest != checksums[name]:
                    raise ValueError(f"Checksum mismatch: {name}")
            gh("release", "upload", tag, str(path), "--repo", target_repo, "--clobber")
            path.unlink()
    for path in helpers:
        gh("release", "upload", tag, str(path), "--repo", target_repo, "--clobber")
    verify_release(target_repo, tag)
    gh("release", "edit", tag, "--repo", target_repo, "--draft=false", "--latest")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    upload = commands.add_parser("upload-docker")
    upload.add_argument("--repo", required=True)
    upload.add_argument("--tag", required=True)
    upload.add_argument("--arch", choices=("x86_64", "arm64"), required=True)
    upload.add_argument("images", nargs="+")
    verify = commands.add_parser("verify")
    verify.add_argument("--repo", required=True)
    verify.add_argument("--tag", required=True)
    copy = commands.add_parser("mirror")
    copy.add_argument("--source-repo", required=True)
    copy.add_argument("--target-repo", required=True)
    copy.add_argument("--tag", required=True)
    copy.add_argument("--notes-file", required=True)
    args = parser.parse_args()
    if args.command == "upload-docker":
        upload_docker(args.repo, args.tag, args.arch, args.images)
    elif args.command == "verify":
        verify_release(args.repo, args.tag)
        print("All platform assets and Docker manifests are complete")
    else:
        mirror(args.source_repo, args.target_repo, args.tag, args.notes_file)


if __name__ == "__main__":
    main()
