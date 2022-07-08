#!/bin/zsh

function get_yc_host_ip {
    echo $(cd ../terraform/stage && terraform show -json | jq ".values.root_module.child_modules[].resources[] | select(.address == \"$1\") | .values.network_interface[0].nat_ip_address")
}

function get_output_var {
    echo $(cd ../terraform/stage && terraform output | grep "$1" | awk '{ print $3 }')
}

case "$1" in
"--list")
    cat<<EOF
{
  "app": {
    "hosts": [
      $(get_yc_host_ip "module.app.yandex_compute_instance.app")
    ],
    "vars": {
      "db_host": $(get_output_var "internal_ip_address_db")
    }
  },
  "db": {
    "hosts": [
      $(get_yc_host_ip "module.db.yandex_compute_instance.db")
    ]
  }
}
EOF
    ;;

"--host")
    cat<<EOF
{
  "_meta": {
    "hostvars": {}
  }
}
EOF
    ;;

*)
    echo "{}"
    ;;
esac
