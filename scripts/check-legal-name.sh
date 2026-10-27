#!/usr/bin/env bash
# Copyright © 2026 TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence. All Rights Reserved.
# rev 272 / rev 275 A2.2: the company is named the registered way everywhere in this repo.
# Alabama Secretary of State, entity 000-579-554: "TeamSmith Enterprises LLC".
#   short form (copyright lines, footers, headers): TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence
#   full form (legal texts): TeamSmith Enterprises LLC, an Alabama limited liability company, doing business as
#                            SurgeXi Business Intelligence
# Fails on the old forms, the misspelling "Teamsmith Enterprises", or the home town.
#   bash scripts/check-legal-name.sh            # the repo
#   bash scripts/check-legal-name.sh --self-test
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2

PATTERNS=(
  -e '[Tt][Ee][Aa][Mm] \?[Ss][Mm][Ii][Tt][Hh] [Ee][Nn][Tt]\. \+LLC \+AL \+Co'
  -e '\b[Aa][Nn]\? \+[Tt]eam \?[Ss]mith Enterprises,\? \?LLC\.\?\( \+AL\.\?\)\? \+[Cc]ompany'
  -e 'Teamsmith Enterprises'
  -e '[Pp]leasant [Gg]rove'
)
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
             "SurgeXi Business Intelligence, A TeamSmith Enterprises LLC. AL. Company."; do
    printf '%s\n' "$old" | grep -q "${PATTERNS[@]}" || { echo "self-test: not caught: $old"; rc=1; }
  done
  for new in "TeamSmith Enterprises LLC d/b/a SurgeXi Business Intelligence" \
             "TeamSmith Enterprises LLC, an Alabama limited liability company, doing business as SurgeXi Business Intelligence"; do
    printf '%s\n' "$new" | grep -q "${PATTERNS[@]}" && { echo "self-test: false hit: $new"; rc=1; }
  done
  [ "$rc" = 0 ] && echo "self-test ok"
  exit "$rc"
fi

hits=$(git grep -n -I "${PATTERNS[@]}" -- . "${EXCLUDE[@]}")
if [ -n "$hits" ]; then
  echo "rev 272: use the registered name (see $SELF):"
  printf '%s\n' "$hits"
  exit 1
fi
echo "legal name ok: no old form, misspelling or home town"
