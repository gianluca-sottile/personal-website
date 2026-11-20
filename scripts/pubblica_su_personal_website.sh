#!/usr/bin/env bash
# Porta la nuova vetrina nel repo personal-website (quello collegato a Netlify),
# senza toccare le impostazioni di Netlify. Poi collega questa cartella a quel repo.
# Uso:  cd ".../academic-website" && bash scripts/pubblica_su_personal_website.sh
set -euo pipefail
SRC="$(pwd)"
TARGET_URL="https://github.com/gianluca-sottile/personal-website.git"
WORK="$HOME/tmp-personal-website"          # fuori da OneDrive

echo "== 1/6 Aggiorno la vetrina locale dal repo academic-website"
git checkout -q publish
git pull -q --rebase origin master

echo "== 2/6 Clono personal-website in $WORK"
rm -rf "$WORK"
git clone -q "$TARGET_URL" "$WORK"
cd "$WORK"
DEFAULT=$(git symbolic-ref --short HEAD)
echo "   ramo pubblicato da Netlify (presumibilmente): $DEFAULT"
if [ -f netlify.toml ]; then echo "   --- netlify.toml attuale (verrà sostituito) ---"; cat netlify.toml; echo "   ---"; fi

echo "== 3/6 Sostituisco i file con la nuova vetrina (il vecchio sito resta nella storia git)"
git rm -rq --ignore-unmatch .
git -C "$SRC" archive publish | tar -x -C .
git add -A
git commit -qm "New academic showcase: bilingual static site with automatic publications"

echo "== 4/6 Controllo di build prima del push"
VENV="$HOME/.venvs/academic-website"
[ -d "$VENV" ] || python3 -m venv "$VENV"
source "$VENV/bin/activate"
pip install -q -r requirements.txt -r requirements-dev.txt
python -m pytest -q
BUILD_ENV=production python scripts/build.py
rm -rf site

echo "== 5/6 Push su personal-website ($DEFAULT) → Netlify ripubblica"
git push origin "$DEFAULT"

echo "== 6/6 Collego la cartella OneDrive a personal-website per le modifiche future"
cd "$SRC"
git remote rename origin academic-website 2>/dev/null || true
git remote add origin "$TARGET_URL"
git fetch -q origin
git checkout -q -B publish "origin/$DEFAULT"
git branch -q --set-upstream-to="origin/$DEFAULT" publish
echo "Fatto. D'ora in poi: git pull, modifica, git commit, git push (ramo publish → $DEFAULT di personal-website)."
