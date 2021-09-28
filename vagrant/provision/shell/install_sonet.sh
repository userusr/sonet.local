#!/usr/bin/env bash
set -Eeuo pipefail

export DOCKER_CLIENT_TIMEOUT=240
export COMPOSE_HTTP_TIMEOUT=240

[ -d ~/sonet.local ] && exit 0

bind_ip=127.0.0.1
rev_ip=0.0.127
up_services=''

if [ "$#" -ge 1 ]; then
    bind_ip=$1
    rev_ip=$(echo "${bind_ip}" | awk -F "." '{print $3"."$2"."$1}')
    shift
    up_services="$@"
fi

sudo apt-get install -y python3-venv

git clone https://github.com/userusr/sonet.local.git
cd sonet.local
git submodule init
git submodule update

make venv
source ./venv/bin/activate

sed -i "s/docker_bind_ip: 127.0.0.1/docker_bind_ip: ${bind_ip}/" inventory/inventory.yml

cat <<EOF>inventory/group_vars/all/05-coredns.yml
---
coredns:
  root_forward: [ '8.8.8.8' ]
  zones:
    - zonefile: "{{ conf['domain'] }}.zone"
      name: "{{ conf['domain'] }}"
      domain_name: "@"
      name_server_fqdn: "ns.{{ conf['domain'] }}."
      admin_email: "root@ns.{{ conf['domain'] }}."
      members:
        - { hostname: '@', type: 'NS', address: "ns.{{ conf['domain'] }}." }
        - { hostname: '', type: 'MX', address: "10 mail.{{ conf['domain'] }}." }
        - { hostname: "ns.{{ conf['domain'] }}.", type: 'A', address: "${bind_ip}" }
        - { hostname: "{{ conf['ldap_hostname'] }}.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "mail.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "gitlab.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "mattermost.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "redmine.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "ldapadmin.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "storage.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "pki.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "excalidraw.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "nextcloud.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "onlyoffice.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "drawio.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "portainer.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "grafana.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "registry.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "adminer.{{ conf['domain'] }}.", type: 'CNAME', address: "ns.{{ conf['domain'] }}." }
    - zonefile: "${rev_ip}.in-addr.arpa.zone"
      name: "${rev_ip}.in-addr.arpa.zone"
      domain_name: "@"
      name_server_fqdn: "ns.{{ conf['domain'] }}."
      admin_email: "root@ns.{{ conf['domain'] }}."
      members:
        - { hostname: '@', type: 'NS', address: "ns.{{ conf['domain'] }}." }
        - { hostname: "ns.{{ conf['domain'] }}.", type: 'PTR', address: "${bind_ip}" }
EOF

make init
make build

./build/sonet_local/sonet up ${up_services}
