#!/bin/bash -e

start_vpn() {
  VPN=$1
  echo "*** Starting docker for $VPN ***"
  RUN="$VPN.sh" docker compose up -d >> /dev/null 2>&1
  sleep 6
}

test_iperf() {
  SERVER_CONTAINER=$1
  CLIENT_CONTAINER=$2
  SERVER_IP=$3
  echo "    Testing iperf from $CLIENT_CONTAINER to $SERVER_CONTAINER"
  echo "$CLIENT_CONTAINER to $SERVER_CONTAINER" >> iperf_report.txt
  docker exec "$SERVER_CONTAINER" iperf -s >> /dev/null 2>&1 &
  SERVER_PID=$!
  disown $SERVER_PID #just to avoid having a kill output message
  sleep 1
  docker exec "$CLIENT_CONTAINER" iperf -c "$SERVER_IP" | awk '/local/ || /Interval/ || /sec/ {print $0}' >> iperf_report.txt
  kill -9 $SERVER_PID >> /dev/null 2>&1
}

test_vpn() {
  VPN=$1
  echo "*** Testing $VPN ***" >> iperf_report.txt
  test_iperf FarS MainS 10.0.2.2
  test_iperf FarC1 MainC1 10.0.2.10
  test_iperf FarC2 Remote 10.0.2.11
}

cleanup() {
  docker compose down -t 1 >> /dev/null 2>&1
}

write_report() {
  echo "*** Appending report for $VPN ***"
  echo "=== End of $VPN report ===" >> iperf_report.txt
  echo "" >> iperf_report.txt
}

trap cleanup EXIT

TESTS=${1:-openvpn wireguard ipsec}

cleanup
echo "*** Removing old report ***"
rm -f iperf_report.txt

for VPN in $TESTS; do
  start_vpn "$VPN"
  test_vpn "$VPN"
  write_report
  echo -e "*** Cleaning up docker for $VPN ***\n"
  cleanup
done

echo "done!"