#!/usr/bin/env bash
set -euo pipefail

OWNER="cnbuyspreadsheet"
REPO="Kakobuy-Spreadsheet"
BASE="https://cnbuyspreadsheet.github.io/Kakobuy-Spreadsheet"
SITE_DIR="/home/zrg/kakobuy-spreadsheet"

cd "$SITE_DIR"

# SECURITY: Do not hardcode GitHub tokens or passwords in this file.
# Non-interactive usage:
#   export GITHUB_TOKEN='your_github_pat_here'
#   ./deploy_to_github_pages.sh
TOKEN="${GITHUB_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  printf 'GitHub token: '
  read -r -s TOKEN
  printf '\n'
fi

if [ -z "$TOKEN" ]; then
  echo "Token is required." >&2
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"
ACCEPT_HEADER="Accept: application/vnd.github+json"

askpass_file=""
cleanup() {
  if [ -n "$askpass_file" ] && [ -f "$askpass_file" ]; then
    rm -f "$askpass_file"
  fi
}
trap cleanup EXIT

# Give git HTTPS credentials non-interactively, so git never asks for username/password.
askpass_file=$(mktemp)
cat > "$askpass_file" <<EOF
#!/usr/bin/env bash
case "\$1" in
  *Username*) printf '%s\n' '$OWNER' ;;
  *Password*) printf '%s\n' '$TOKEN' ;;
  *) printf '%s\n' '$TOKEN' ;;
esac
EOF
chmod 700 "$askpass_file"
export GIT_ASKPASS="$askpass_file"
export GIT_TERMINAL_PROMPT=0

echo "[1/7] Running local predeploy check..."
python3 ~/.hermes/skills/static-site-patterns/scripts/static_site_predeploy_check.py "$SITE_DIR" "$BASE"

echo "[2/7] Verifying GitHub token..."
LOGIN=$(curl -fsS -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" https://api.github.com/user | python3 -c 'import sys,json; print(json.load(sys.stdin).get("login",""))')
echo "Authenticated as: $LOGIN"
if [ "$LOGIN" != "$OWNER" ]; then
  echo "Token user '$LOGIN' does not match expected owner '$OWNER'." >&2
  exit 1
fi

echo "[3/7] Ensuring repository exists..."
STATUS=$(curl -sS -o /tmp/kakobuy_repo_check.json -w '%{http_code}' -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "https://api.github.com/repos/$OWNER/$REPO")
if [ "$STATUS" = "404" ]; then
  curl -fsS -X POST -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" https://api.github.com/user/repos \
    -d "{\"name\":\"$REPO\",\"private\":false,\"description\":\"KakoBuy Spreadsheet static SEO site for GitHub Pages\",\"has_issues\":true,\"has_wiki\":false}" >/tmp/kakobuy_repo_create.json
  echo "Repository created: https://github.com/$OWNER/$REPO"
elif [ "$STATUS" = "200" ]; then
  echo "Repository already exists: https://github.com/$OWNER/$REPO"
else
  echo "Repository check failed with HTTP $STATUS" >&2
  cat /tmp/kakobuy_repo_check.json >&2
  exit 1
fi

echo "[4/7] Committing local site..."
git init -q
git branch -M main
git config user.name "$OWNER"
git config user.email "$OWNER@users.noreply.github.com"
git add .
if git diff --cached --quiet; then
  echo "No new changes to commit."
else
  git commit -m "Deploy Kakobuy Spreadsheet static site"
fi

echo "[5/7] Pushing to GitHub..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$OWNER/$REPO.git"
# GIT_ASKPASS supplies username/token; GIT_TERMINAL_PROMPT=0 prevents any interactive prompt.
git push -u origin main --force
git remote set-url origin "https://github.com/$OWNER/$REPO.git"

echo "[6/7] Enabling GitHub Pages from main / root..."
PAGES_STATUS=$(curl -sS -o /tmp/kakobuy_pages_check.json -w '%{http_code}' -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "https://api.github.com/repos/$OWNER/$REPO/pages")
if [ "$PAGES_STATUS" = "404" ]; then
  curl -fsS -X POST -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "https://api.github.com/repos/$OWNER/$REPO/pages" \
    -d '{"source":{"branch":"main","path":"/"}}' >/tmp/kakobuy_pages_create.json
  echo "GitHub Pages created."
elif [ "$PAGES_STATUS" = "200" ]; then
  curl -fsS -X PUT -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "https://api.github.com/repos/$OWNER/$REPO/pages" \
    -d '{"source":{"branch":"main","path":"/"}}' >/tmp/kakobuy_pages_update.json
  echo "GitHub Pages updated."
else
  echo "Pages check failed with HTTP $PAGES_STATUS" >&2
  cat /tmp/kakobuy_pages_check.json >&2
  exit 1
fi

echo "[7/7] Final Pages status..."
curl -fsS -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "https://api.github.com/repos/$OWNER/$REPO/pages" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("Repository: https://github.com/cnbuyspreadsheet/Kakobuy-Spreadsheet"); print("Pages URL: "+str(d.get("html_url"))); print("Status: "+str(d.get("status"))); print("Source: "+str(d.get("source",{}).get("branch"))+" "+str(d.get("source",{}).get("path")))'

echo "Done. If GitHub Pages is still building, wait 1-3 minutes then open: $BASE/"
