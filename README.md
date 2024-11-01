# Terraforms for Benchmarking EC2 Instances

Creates three different types of EC2 instances each in their own
subnet. Includes a simple script for counting incoming PPS.

## Network Performance

To bombard a machine with packets, easiest is to just run:

```
sudo yum install iperf

# Send 5Gbps
sudo iperf -c 10.0.2.10 -u -i 1 -b 5G -e -t 600

# Send 2M PPS
sudo iperf -c 10.0.2.10 -l 1 -P100   -u -i 1 -b 20kpps -e -t 600
```

Use `ethtool -S ens5` to view any throttling on receiving end.
