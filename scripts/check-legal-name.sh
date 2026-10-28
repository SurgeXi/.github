#!/usr/bin/env bash
# Copyright © 2026 TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence. All Rights Reserved.
# rev 272 / rev 275 A2.2 / rev 276 A1: the company is named one of TWO approved ways (Todd, Oct 28):
#   Legal   (contracts, legal texts' next version, LICENSE / repo notice, contract-party lines):
#           TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence
#           (where a contract states the party: "..., an Alabama limited liability company, doing business as ...")
#   Display (footers, marketing pages, descriptions, social and promotional copy):
#           © SurgeXi Business Intelligence, a TeamSmith Ent. LLC AL co.
# Fails on the old forms and the misspelling "Teamsmith Enterprises"; on the home town everywhere.
# HOLD: a copyright COMMENT line (the source-file header, wherever it sits) waits on Todd's
# Legal-or-Display answer, so it is not checked for the old forms yet.
#   bash scripts/check-legal-name.sh            # the repo
#   bash scripts/check-legal-name.sh --self-test
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2

DISPLAY='© SurgeXi Business Intelligence, a TeamSmith Ent. LLC AL co.'
OLD=(
  -e '[Tt][Ee][Aa][Mm] \?[Ss][Mm][Ii][Tt][Hh] [Ee][Nn][Tt]\. \+LLC \+AL \+Co'
  -e '\b[Aa][Nn]\? \+[Tt]eam \?[Ss]mith Enterprises,\? \?LLC\.\?\( \+AL\.\?\)\? \+[Cc]ompany'
  -e 'Teamsmith Enterprises'
)
HOME_TOWN=(-e '[Pp]leasant [Gg]rove')
# one line: $1 = its line number, $2 = its text. Hit = home town anywhere, or an old form outside
# a held header once the Display string itself is taken out.
is_hit() {
  printf '%s\n' "$2" | grep -q "${HOME_TOWN[@]}" && return 0
  [[ "$2" == *Copyright* ]] && [[ "$2" =~ ^[[:space:]]*(#|//|/\*|\*|<!--|--|;|%|\{/\*) ]] && return 1
  printf '%s\n' "${2//"$DISPLAY"/}" | grep -q "${OLD[@]}"
}
SELF=scripts/check-legal-name.sh
# Not scanned (each with its reason):
EXCLUDE=(
  ":!$SELF"
  # applied database migrations are immutable: a changed byte changes the checksum and fails validation
  ':(exclude,glob)**/*migration*/**/*.sql'
  ':(exclude,glob)**/migrations/**/*.sql'
)

if [ "${1:-}" = "--self-test" ]; then
  rc=0
  for old in "A TeamSmith Ent. LLC AL Co." "a Teamsmith Enterprises LLC company" \
             "SurgeXi Business Intelligence, A Teamsmith Enterprises LLC AL company" "Pleasant Grove, Alabama" \
             "SurgeXi Business Intelligence. A TeamSmith Enterprises, LLC. AL company." \
             "SurgeXi Business Intelligence, A TeamSmith Enterprises LLC. AL. Company." \
             "prior written permission of Teamsmith Enterprises LLC"; do
    is_hit 9 "$old" || { echo "self-test: not caught: $old"; rc=1; }
  done
  for new in "TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence" "$DISPLAY" \
             "TeamSmith Enterprises LLC, an Alabama limited liability company, doing business as SurgeXi Business Intelligence"; do
    is_hit 9 "$new" && { echo "self-test: false hit: $new"; rc=1; }
  done
  # HOLD: an old-form copyright comment is not a hit yet; the home town still is; the same text outside a comment is
  is_hit 1 "# Copyright © 2026 SurgeXi Business Intelligence, a Teamsmith Enterprises LLC company." && { echo "self-test: held header hit"; rc=1; }
  is_hit 1 "# Copyright © 2026 Pleasant Grove" || { echo "self-test: home town in a header not caught"; rc=1; }
  is_hit 60 "<!-- Copyright © 2026 SurgeXi Business Intelligence, a Teamsmith Enterprises LLC company. -->" && { echo "self-test: held header after front matter hit"; rc=1; }
  is_hit 6 "© 2026 SurgeXi Business Intelligence, a Teamsmith Enterprises LLC company." || { echo "self-test: old line outside a comment not caught"; rc=1; }
  [ "$rc" = 0 ] && echo "self-test ok"
  exit "$rc"
fi

hits=()
while IFS= read -r h; do
  f=${h%%:*}; rest=${h#*:}; n=${rest%%:*}; t=${rest#*:}
  is_hit "$n" "$t" && hits+=("$h")
done < <(git grep -n -I "${OLD[@]}" "${HOME_TOWN[@]}" -- . "${EXCLUDE[@]}")
if [ "${#hits[@]}" -gt 0 ]; then
  echo "rev 276 A1: use the Legal or the Display form (see $SELF):"
  printf '%s\n' "${hits[@]}"
  exit 1
fi
echo "company name ok: Legal or Display only (file headers on hold); no home town"
