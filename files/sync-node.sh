#! /bin/bash

do_sync(){
	local AVAILABILITY REMOVE_LABELS LABEL LABEL_NAME LABEL_VALUE ARGS=() LABEL_NAMES=() NODE_NAME
	while ARG="$1" && shift; do
		case "$ARG" in
		"--availability")
			AVAILABILITY="$1" && shift || break;
			ARGS=("${ARGS[@]}" "--availability" "$AVAILABILITY")
			;;
		"--remove-labels")
			REMOVE_LABELS='Y'
			;;
		"--label-add")
			LABEL="$1" && shift || break;
			IFS='=' read LABEL_NAME LABEL_VALUE<<<"$LABEL" && {
				ARGS=("${ARGS[@]}" "--label-add" "$LABEL")
				LABEL_NAMES=("${LABEL_NAMES[@]}" "$LABEL_NAME")
			}
			;;
		*)
			NODE_NAME="$ARG"; 
			;;
		esac
	done
	[ ! -z "$NODE_NAME" ] || {
		echo "Usage: $(basename "$0") [--availability 'active'] [--remove-labels] [--label-add 'name=value'] <node_name>" >&2
		return 1
	}
	local ACTUAL_AVAILABILITY ACTUAL_LABEL_NAME
	[ ! -z "$REMOVE_LABELS" ] && {
		read -r ACTUAL_AVAILABILITY && while read -r ACTUAL_LABEL_NAME; do 
			[ -z "$ACTUAL_LABEL_NAME" ] && continue
			for LABEL_NAME in "${LABEL_NAMES[@]}"; do
				[ "$ACTUAL_LABEL_NAME" = "$LABEL_NAME" ] && continue 2
			done
			ARGS=("${ARGS[@]}" "--label-rm" "$ACTUAL_LABEL_NAME")
		done
	} < <(docker node inspect -f '{{.Spec.Availability}}'$'\n''{{range $k,$v:=.Spec.Labels}}{{$k}}'$'\n''{{end}}' "$NODE_NAME")

	echo docker node update "${ARGS[@]}" "$NODE_NAME" >&2
	docker node update "${ARGS[@]}" "$NODE_NAME" || return 1
	return 0
}

do_sync "$@"
