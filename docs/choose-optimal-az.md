# Choosing the Optimal Availability Zone

Based on typical measurements, the `ap-northeast-1` region (Tokyo) provides the lowest latency to Binance's FIX servers. However, the optimal AZ within that region varies.

After choosing AWS region, choosing the Availability Zone (AZ) has the biggest effect on the trading latency. Selecting the optimal AZ can reduce round-trip time by several milliseconds.

AZ zone names (e.g., `ap-northeast-1a`) map to different physical data centers for different AWS accounts. What's `ap-northeast-1a` for one account might be a different physical location for another. **Therefore, you must measure latency from your own AWS account.**

## Measuring

Run the latency measurement utility to test all availability zones in the `ap-northeast-1` region:

```bash
just deploy::measure-latency
```

This command uses Terraform to:

1. Fetch all available AZs in the `ap-northeast-1` region
2. Launch a temporary `t3.micro` EC2 instance in each AZ
3. Install `nmap` (for `nping`) on each instance
4. Run 100 TCP probes against `fix-md.binance.com:9000`
5. Display the results for each AZ
6. Automatically destroy all instances and clean up resources

### Interpreting Results

The utility outputs `nping` results for each AZ during the Terraform apply:

```
=== Latency measurement for ap-northeast-1a ===
Target: fix-md.binance.com:9000
Probes: 100

Max rtt: 1.009ms | Min rtt: 0.513ms | Avg rtt: 0.552ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.21 seconds
```

Key metrics to consider:

| Metric      | Description                                          | Priority |
| ----------- | ---------------------------------------------------- | -------- |
| **Avg rtt** | Average round-trip time - primary selection criteria | High     |
| **Min rtt** | Best-case latency                                    | Medium   |
| **Max rtt** | Worst-case latency (indicates jitter)                | Medium   |
| **Lost**    | Packet loss percentage (should be 0%)                | High     |

**Select the AZ with the lowest average RTT and zero packet loss.**