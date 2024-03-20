$TTL 86400
@   IN  SOA     ns.hospital.com. admin.hospital.com. (
                    2022021001  ; Serial
                    3600        ; Refresh
                    1800        ; Retry
                    604800      ; Expire
                    86400       ; Minimum TTL
)
;
@           IN  NS  ns.hospital.com.
@           IN  A   192.168.1.1
ns          IN  A   192.168.1.1
SRV-ODOO    IN  A   192.168.1.2
SRV-HPOT    IN  A   192.168.100.2
