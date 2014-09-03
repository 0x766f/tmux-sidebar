#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/variables.sh"

# script global vars
ARGS="$1"               # example args format: "tree | less,right,20,focus"
PANE_CURRENT_PATH="$2"
COMMAND="$(echo "$ARGS"  | cut -d',' -f1)"   # "tree | less"
POSITION="$(echo "$ARGS" | cut -d',' -f2)"   # "right"
SIZE="$(echo "$ARGS"     | cut -d',' -f3)"   # "20"
FOCUS="$(echo "$ARGS"    | cut -d',' -f4)"   # "focus"


PANE_ID="$TMUX_PANE"


supported_tmux_version_ok() {
	$CURRENT_DIR/check_tmux_version.sh "$SUPPORTED_TMUX_VERSION"
}

sidebar_pane_id() {
	get_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" ""
}

register_new_sidebar() {
	set_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" "$1"
}

pane_exists() {
	local pane_id="$1"
	tmux list-panes -F "#{pane_id}" 2>/dev/null |
		\grep -q "^${pane_id}$"
}

has_sidebar() {
	local sidebar_pane_id="$(sidebar_pane_id)"
	if [ -n $sidebar_pane_id ] && pane_exists "$sidebar_pane_id"; then
		return 0
	else
		return 1
	fi
}

kill_sidebar() {
	tmux kill-pane -t "$(sidebar_pane_id)"
}

orientation_option() {
	echo "-h"
}

sidebar_left() {
	[[ $POSITION =~ "left" ]]
}

no_focus() {
	if [[ $FOCUS =~ (^focus) ]]; then
		return 1
	else
		return 0
	fi
}

size_defined() {
	[ -n $SIZE ]
}

create_sidebar() {
	local new_sidebar_id=$(tmux split-window "$(orientation_option)" -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}" "$COMMAND")
	register_new_sidebar "$new_sidebar_id"
	if sidebar_left; then
		tmux swap-pane -U
	fi
	if size_defined; then
		tmux resize-pane -x "$SIZE"
	fi
	if no_focus; then
		tmux last-pane
	fi
}

toggle_sidebar() {
	if has_sidebar; then
		kill_sidebar
	else
		create_sidebar
	fi
}

main() {
	if supported_tmux_version_ok; then
		toggle_sidebar
	fi
}
main
