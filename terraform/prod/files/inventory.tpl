[app]
appserver ansible_host=${app_ip_address} db_host=${db_internal_ip_address}

[db]
dbserver ansible_host=${db_ip_address}
