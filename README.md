# failover_cloudflare
As soon as your website becomes unavailable, all traffic will be switched over to the configured backup IP address automatically using cron. This can be another server or load-balancer.

./failover_cloudflare.sh  -e CloudflareEmail -k CloudflareApiKey -n DomainHosted -p newDNS -c IpToCheck
