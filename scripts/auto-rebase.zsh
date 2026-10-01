#!/usr/bin/env zsh

# Squash the linear commits after an explicitly supplied split commit.
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

die() {
  print -ru2 -- "auto-rebase: $*"
  exit 1
}

usage() {
  print -r -- 'Usage: auto-rebase.zsh [-y] HASH'
  print -r -- 'Squash commits after HASH, keeping the first message.'
  print -r -- '  -y          Push to the configured upstream with --force-with-lease.'
  print -r -- '  -h, --help  Show this help.'
}

auto_push=0
split_arg=''
for arg in "$@"; do
  case "$arg" in
    -y) auto_push=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) usage >&2; die "Unknown argument: $arg" ;;
    *) [[ -z "$split_arg" ]] || { usage >&2; die 'Only one HASH may be supplied.'; }; split_arg="$arg" ;;
  esac
done
[[ -n "$split_arg" ]] || { usage >&2; die 'A split commit HASH is required.'; }

[[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == true ]] ||
  die 'Run this script inside a Git working tree.'
branch=$(git symbolic-ref --quiet --short HEAD) || die 'Detached HEAD is not supported.'
case "$branch" in
  main|master) die "Refusing to rewrite protected branch '$branch'." ;;
esac

for operation in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD sequencer BISECT_START; do
  [[ ! -e "$(git rev-parse --git-path "$operation")" ]] ||
    die "A Git operation is already in progress ($operation). Finish or abort it first."
done
worktree_status=$(git status --porcelain=v1 --untracked-files=all --ignore-submodules=none) ||
  die 'Cannot inspect the working tree.'
[[ -z "$worktree_status" ]] ||
  die 'The index and working tree must be clean, including untracked files.'

upstream=''
remote=''
destination=''
upstream_tip=''
if (( auto_push )); then
  upstream=$(git rev-parse --symbolic-full-name '@{upstream}' 2>/dev/null) ||
    die 'The current branch must have a configured upstream when using -y.'
  remote=$(git for-each-ref --format='%(upstream:remotename)' "refs/heads/$branch")
  destination=$(git for-each-ref --format='%(upstream:remoteref)' "refs/heads/$branch")
  [[ -n "$remote" && "$remote" != . && "$destination" == refs/heads/* ]] ||
    die 'The upstream must be a branch on a configured remote.'
  git remote get-url --push "$remote" >/dev/null 2>&1 || die 'The upstream remote has no push URL.'
  case "$destination" in
    refs/heads/main|refs/heads/master) die "Refusing to push to protected upstream '$destination'." ;;
  esac
  upstream_tip=$(git rev-parse --verify "${upstream}^{commit}") || die 'The upstream commit is unavailable.'
fi

# Capture the lease before rewriting; background fetches must not weaken it.
original_head=$(git rev-parse HEAD)
split=$(git rev-parse --verify "${split_arg}^{commit}") || die "Invalid split commit: $split_arg"
git merge-base --is-ancestor "$split" "$original_head" || die 'The split point is not an ancestor of HEAD.'
[[ -z "$(git rev-list --merges "$split..$original_head")" ]] ||
  die 'The topic history contains merge commits; a linear history is required.'
count=$(git rev-list --count "$split..$original_head")
(( count >= 2 )) || die "At least two commits after the split point are required (found $count)."
first=$(git rev-list --reverse "$split..$original_head" | sed -n '1p')

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/auto-rebase.XXXXXXXX") || die 'Cannot create temporary directory.'
temp_dir=${temp_dir:A}
trap 'rm -rf -- "$temp_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

git show --no-patch --format=format:%B "$first" > "$temp_dir/message"
cat > "$temp_dir/sequence-editor" <<'EDITOR'
#!/bin/sh
set -eu
awk '
  $1 == "pick" { if (seen++) sub(/^pick /, "squash ") }
  { print }
' "$1" > "$1.auto-rebase"
mv "$1.auto-rebase" "$1"
EDITOR
cat > "$temp_dir/message-editor" <<'EDITOR'
#!/bin/sh
set -eu
cp "$AUTO_REBASE_MESSAGE" "$1"
EDITOR
chmod +x "$temp_dir/sequence-editor" "$temp_dir/message-editor"

print -r -- "Squashing $count commits on '$branch' after $split."
# Git interprets editor variables as shell commands; quote paths (including spaces
# and apostrophes) using zsh's POSIX-compatible quoting expansion.
if ! GIT_SEQUENCE_EDITOR="${(q)temp_dir}/sequence-editor" \
     GIT_EDITOR="${(q)temp_dir}/message-editor" \
     AUTO_REBASE_MESSAGE="$temp_dir/message" \
     git -c rebase.abbreviateCommands=false -c rebase.instructionFormat=%s \
         -c commit.cleanup=verbatim rebase -i --no-autosquash --no-autostash \
         --no-update-refs --no-fork-point --keep-empty --empty=keep \
         --reapply-cherry-picks "$split"; then
  print -ru2 -- "Rebase failed; nothing was pushed. Original HEAD: $original_head"
  print -ru2 -- "Inspect git status; use git rebase --abort to undo an active rebase."
  print -ru2 -- "If continuing manually, retain the message from commit $first."
  exit 1
fi

if (( auto_push )); then
  if ! git push "--force-with-lease=$destination:$upstream_tip" -- "$remote" "HEAD:$destination"; then
    die 'Rebase succeeded, but the push failed. The local squashed commit is retained; inspect the remote before retrying.'
  fi
  print -r -- 'Rebase and push were successful.'
else
  print -r -- 'Rebase was successful now you can make `git push -f`'
fi
