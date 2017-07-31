#! /bin/bash

STACKS_DIR=
STACKS_CHANGED=

prepare(){
	STACKS_DIR="$1"
	[ ! -z "$STACKS_DIR" ] || STACKS_DIR="$(mktemp -d -t npc-stacks.XXXXXX)"
	mkdir -p "$STACKS_DIR" && cd "$STACKS_DIR" && rm -fr ./* || return 1
}

apply(){
	STACKS_DIR="$1"
	[ ! -z "$STACKS_DIR" ] && cd "$STACKS_DIR" || {
		echo 'STACKS_DIR=""'
		return 1
	}
	trap "[ -f apply.log ] && cat apply.log; rm -fr $STACKS_DIR" EXIT
	
	local REMOVES STACK STACK_FILE
	[ -f .removes ] && REMOVES="$(<.removes)" && rm -f .removes

	for STACK_FILE in *.*; do 
		[ ! -f "${STACK_FILE%.*}.stack" ] && cp "$STACK_FILE" "${STACK_FILE%.*}.stack"
	done

	> apply.log
	while read -r STACK _; do
		[ ! -z "$REMOVES" ] && (
			set -f
			for REMOVE in $REMOVES; do
				[[ "$STACK" == $REMOVE ]] && [ ! -f "$STACK.stack" ] && {
					docker stack rm "$STACK" &>> apply.log || return 1
					exit 0
					break
				} 
			done
			exit 1
		) && STACKS_CHANGED='true'
	done < <(docker stack ls | (read && cat))

	for STACK_FILE in *.stack; do 
		STACK="${STACK_FILE##*/}" && STACK="${STACK%.stack}"
		docker stack deploy -c "$STACK_FILE" "$STACK" &>> apply.log || return 1
		STACKS_CHANGED='true'
	done
	return 0
}

report(){
	[ -f apply.log ] && rm -f apply.log
cat<<EOF
{
	"changed":${STACKS_CHANGED:-false},
	"path":"$STACKS_DIR"
}
EOF
}

while ARG="$1" && shift; do
	case "$ARG" in
	"--prepare")
		prepare "$@" && report && exit 0
		;;
	"--apply")
		apply "$@" && report && exit 0
		;;
	esac
done
exit 1
