#!/bin/sh
# Claude Code status line — minimal + optimal
# Line 1: model | context% | cost | 5h rate limit
# Line 2: git branch +staged ~modified

input=$(cat)

# --- Claude context ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | awk '{printf "%.0f", $1}')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Colors
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Context % with token counts
ctx_tokens_str=""
if [ -n "$used" ]; then
  ctx_val=$(printf "%.0f" "$used")
  if [ "$ctx_val" -ge 80 ]; then ctx_color="$RED"
  elif [ "$ctx_val" -ge 50 ]; then ctx_color="$YELLOW"
  else ctx_color="$GREEN"
  fi
  ctx_used=$(echo "$input" | jq -r '(.context_window.current_usage.cache_read_input_tokens + .context_window.current_usage.cache_creation_input_tokens + .context_window.current_usage.input_tokens + .context_window.current_usage.output_tokens) // empty' 2>/dev/null)
  ctx_total=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
  if [ -n "$ctx_used" ] && [ -n "$ctx_total" ]; then
    ctx_used_k=$(( ctx_used / 1000 ))
    ctx_total_k=$(( ctx_total / 1000 ))
    ctx_tokens_str=" ${DIM}(${ctx_used_k}k/${ctx_total_k}k)${RESET}"
  fi
  ctx_str="${ctx_color}${ctx_val}%${RESET}${ctx_tokens_str}"
else
  ctx_str="${DIM}0%${RESET}"
fi

# Cost
if [ -n "$total_cost" ]; then
  cost_display=$(awk "BEGIN { printf \"%.2f\", $total_cost }")
  cost_str="\$${cost_display}"
else
  cost_str="\$0.00"
fi

# 5h rate limit bar
make_bar() {
  pct="$1"
  width=10
  filled=$(( pct * width / 100 ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  while [ $i -lt $width ];  do bar="${bar}░"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

# Compute relative time until reset
time_until() {
  ts="$1"
  [ -z "$ts" ] && return
  now=$(date +%s)
  diff=$(( ts - now ))
  [ "$diff" -le 0 ] && printf "now" && return
  hours=$(( diff / 3600 ))
  minutes=$(( (diff % 3600) / 60 ))
  if [ "$hours" -gt 0 ]; then
    printf "%dh %dm" "$hours" "$minutes"
  else
    printf "%dm" "$minutes"
  fi
}

rl_str=""
if [ -n "$rl_5h_pct" ]; then
  if [ "$rl_5h_pct" -ge 90 ]; then rl_color="$RED"
  elif [ "$rl_5h_pct" -ge 70 ]; then rl_color="$YELLOW"
  else rl_color="$GREEN"
  fi
  delta=$(time_until "$rl_5h_reset")
  bar=$(make_bar "$rl_5h_pct")
  rl_str="${rl_color}5h ${bar} ${rl_5h_pct}%"
  [ -n "$delta" ] && rl_str="${rl_str} (${delta})"
  rl_str="${rl_str}${RESET}"
fi

# Folder name
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$dir" ]; then
  repo_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")
  dir_name=$(basename "$repo_root")
else
  dir_name=""
fi

# Git info
git_str=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

  git_str="$branch"
  [ "$staged" -gt 0 ] && git_str="${git_str} ${GREEN}+${staged}${RESET}"
  [ "$modified" -gt 0 ] && git_str="${git_str} ${YELLOW}~${modified}${RESET}"
fi

# --- Output ---
# Line 1: model | context | cost | rate limit
line1="${DIM}${model}${RESET} | ${ctx_str} | ${DIM}${cost_str}${RESET}"
[ -n "$rl_str" ] && line1="${line1} | ${rl_str}"

# Line 2: folder | git branch +staged ~modified | worktree (if active)
line2=""
[ -n "$dir_name" ] && line2="${DIM}${dir_name}${RESET}"
[ -n "$git_str" ] && line2="${line2:+${line2} | }${git_str}"
[ -n "$worktree" ] && line2="${line2:+${line2} | }${DIM}wt:${worktree}${RESET}"

if [ -n "$line2" ]; then
  printf "%b\n%b\n" "$line1" "$line2"
else
  printf "%b\n" "$line1"
fi
