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
| Padding                   | Buffers incoming bytes and creates a 512-bit message chunk consisting of the message bytes,  followed by a '1', zero-padding and the 64-bit message length |
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

## Performance & Resource Utilization

Target Device: Xilinx Artix-7 XC7A35TCPG236-1

| Resource      | Used | Available | Utilization % |
| :------------ | ---: | --------: | ------------: |
| LUTs          | 1384 |     20800 |          6.65 |
| Registers     | 2224 |     41600 |          5.35 |
| Block RAM     |    1 |        50 |          2.00 |
| DSP Slices    |    0 |        90 |          0.00 |
