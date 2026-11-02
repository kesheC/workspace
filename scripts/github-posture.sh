#!/usr/bin/env bash
# Report the repository-level posture of every shipped project.
# A repo is only finished when every column reads the good value; the script
# exits non-zero and names the failing repo otherwise.
#
# Usage: bash scripts/github-posture.sh [owner] [repo ...]
#   owner defaults to kesheC, repos default to the six projects plus workspace.
set -uo pipefail
owner=${1:-kesheC}
shift || true
repos=("$@")
if [ ${#repos[@]} -eq 0 ]; then
  repos=(repropack clidoc envpulse gitignore-doctor jsonl-beaver apidiff workspace)
fi

printf '%-17s %-7s %-7s %-6s %-6s %-6s %-5s %-6s %-10s\n' \
  repo version topics health scan push-prot pvr ci release
status=0

for r in "${repos[@]}"; do
  ver=$(gh api "repos/$owner/$r/contents/package.json" --jq .content 2>/dev/null \
    | base64 -d 2>/dev/null \
    | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{process.stdout.write(JSON.parse(s).version)}catch{process.stdout.write('-')}})" 2>/dev/null)
  [ -n "$ver" ] || ver='-'
  topics=$(gh api "repos/$owner/$r/topics" --jq '.names|length' 2>/dev/null || echo '-')
  health=$(gh api "repos/$owner/$r/community/profile" --jq '.health_percentage' 2>/dev/null || echo '-')
  scan=$(gh api "repos/$owner/$r" --jq '.security_and_analysis.secret_scanning.status' 2>/dev/null || echo '-')
  pushp=$(gh api "repos/$owner/$r" --jq '.security_and_analysis.secret_scanning_push_protection.status' 2>/dev/null || echo '-')
  pvr=$(gh api "repos/$owner/$r/private-vulnerability-reporting" --jq '.enabled' 2>/dev/null || echo '-')
  ci=$(gh run list --repo "$owner/$r" --workflow CI --limit 1 --json conclusion --jq '.[0].conclusion // "-"' 2>/dev/null || echo '-')
  rel=$(gh api "repos/$owner/$r/releases/latest" \
    --jq '.tag_name + " (" + ((.assets|length)|tostring) + " assets)"' 2>/dev/null | head -1)
  # gh api prints the error body on stdout when it fails, so keep the value only
  # if it still looks like a release tag.
  case "$rel" in v*) ;; *) rel='-' ;; esac

  printf '%-17s %-7s %-7s %-6s %-6s %-6s %-5s %-6s %-10s\n' \
    "$r" "$ver" "$topics" "$health" "$scan" "$pushp" "$pvr" "$ci" "$rel"

  [ "$health" = "100" ] || { echo "  ^ $r: community profile is not complete ($health%)" >&2; status=1; }
  [ "$scan" = "enabled" ] || { echo "  ^ $r: secret scanning is off" >&2; status=1; }
  [ "$pushp" = "enabled" ] || { echo "  ^ $r: push protection is off" >&2; status=1; }
  [ "$pvr" = "true" ] || { echo "  ^ $r: private vulnerability reporting is off" >&2; status=1; }
done

exit $status