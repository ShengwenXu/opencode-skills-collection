#!/usr/bin/env bash
set -eu

archive_url='https://raw.githubusercontent.com/ShengwenXu/opencode-skills-collection/main/skills.zip'
expected_sha256='5be4e6ae10e1739dd6529eac138faf6ee637e236a23a343523b5ad9dff368a1a'
skills_root="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/opencode-skills.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

curl --fail --location --silent --show-error "$archive_url" -o "$work_dir/skills.zip"
actual_sha256="$(shasum -a 256 "$work_dir/skills.zip" | cut -d ' ' -f 1)"
if [ "$actual_sha256" != "$expected_sha256" ]; then
  echo 'Archive checksum mismatch; installation stopped.' >&2
  exit 1
fi
unzip -q "$work_dir/skills.zip" -d "$work_dir"
mkdir -p "$skills_root"
installed=0
skipped=0
for source_dir in "$work_dir"/skills/*; do
  [ -f "$source_dir/SKILL.md" ] || continue
  skill_id="$(basename "$source_dir")"
  destination="$skills_root/$skill_id"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'SKIP %s\n' "$skill_id"
    skipped=$((skipped + 1))
  else
    cp -R "$source_dir" "$destination"
    printf 'INSTALLED %s\n' "$skill_id"
    installed=$((installed + 1))
  fi
done
printf '\nInstalled: %s; already present: %s\n' "$installed" "$skipped"
