#! /bin/bash

DOCKER_INSTALLED=
DOCKER_VERSION="$(docker version -f '{{.Server.Version|json}}')"
[ ! -z "$DOCKER_VERSION" ] && DOCKER_INSTALLED='true'

SWARM_ROLE=
SWARM_IS_ACTIVE="$(docker info -f '{{if eq .Swarm.LocalNodeState "active"}}true{{end}}')"
[ ! -z "$SWARM_IS_ACTIVE" ] && SWARM_ROLE='worker'
SWARM_IS_MANAGER="$(docker info -f '{{if .Swarm.ControlAvailable }}true{{end}}')"
[ ! -z "$SWARM_IS_MANAGER" ] && SWARM_ROLE='manager'

SWARM_NODE_ID="$(docker info -f '{{.Swarm.NodeID|json}}')"
SWARM_NODE_ADDR="$(docker info -f '{{.Swarm.NodeAddr|json}}')"
SWARM_MANAGERS=
for ADDR in $(docker info -f '{{range .Swarm.RemoteManagers}}{{.Addr}} {{end}}'); do
	SWARM_MANAGERS="${SWARM_MANAGERS:+$SWARM_MANAGERS,}\"${ADDR%:*}\""
done

cat<<EOF
{
	"is_installed":${DOCKER_INSTALLED:-false},
	"version":${DOCKER_VERSION:-null},
	"swarm":{
		"is_active":${SWARM_IS_ACTIVE:-false},
		"is_manager":${SWARM_IS_MANAGER:-false},
		"role":"$SWARM_ROLE",
		"node_id":${SWARM_NODE_ID:-null},
		"node_addr":${SWARM_NODE_ADDR:-null},
		"managers":[${SWARM_MANAGERS}]
	}
}
EOF