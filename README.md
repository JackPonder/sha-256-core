# SHA-256 Hardware Core

A hardware implementation of the SHA-256 cryptographic hash algorithm written in 
SystemVerilog and designed for FPGA deployment. The system communicates with a host 
computer over UART, allowing input messages to be transmitted to the FPGA and the 
resulting 256-bit SHA-256 digest to be returned as a hexadecimal ASCII string.

## System Architecture

The system is structured as a modular pipelined processing chain. Each module 
transmits data with the previous and next modules via AXI-style ready/valid handshakes. 

### Block Diagram

![Block Diagram](docs/block-diagram.png)

### Module Overview 

| Module                    | Description |
| :---                      | :--- |
| UART Receiver             | Deserializes message bytes from the host computer and passes them to the SHA-256 core. |
| Padding                   | Buffers incoming bytes and creates 512-bit message chunks for processing |
| Processing                | Implements the core cryptographic digest algorithm, consisting of 64-word message scheduling,  working variable initialization, and a 64-iteration compression loop |
| Digest-to-ASCII Converter | Converts the 256-bit digest to hexadecimal ASCII characters, followed by a carriage return and  line feed |
| UART Transmitter          | Serializes and transmits the resulting ASCII characters |

## Verification

The SHA-256 core has been verified using automated SystemVerilog testbenches, 
with test vectors from https://di-mgt.com.au/sha_testvectors.html.

### Example Test Vector

```
Input Text: "abc"
Expected Output: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

## Resource Utilization

Target Device: Xilinx Artix-7 XC7A35TCPG236-1

| Resource            | Used | Available | Utilization % |
| :------------------ | ---: | --------: | ------------: |
| Slice LUTs          | 1284 |     20800 |          6.17 |
| Slice Registers     | 2118 |     41600 |          5.09 |
| Block RAM           |  0.5 |        50 |          1.00 |
| DSP Slices          |    0 |        90 |          0.00 |

## Performance

| Metric                    |    Result |
| :------------------------ | --------: |
| Max Frequency             |   109 MHz |
| Cycles per 512-bit block  |        68 |
| Latency                   |    624 ns |
| Throughput                |  820 Mb/s |
