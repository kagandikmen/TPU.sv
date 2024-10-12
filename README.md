# TPU.sv

TPU.sv is a reconstruction of Google's TPU (v1) in SystemVerilog. The primary objective of this project is to develop a generic and resource-adjustable machine learning inference accelerator for educational purposes.

## Approach

The following sources have been primarily referenced for this project:

- [Google's 2018 paper introducing TPU's architecture](https://arxiv.org/abs/1704.04760)
- ["Implementierung einer Tensor Processing Unit" by Jonas Fuhrmann](https://reposit.haw-hamburg.de/handle/20.500.12738/8527)
- [tinyTPU by Jonas Fuhrmann](https://github.com/jofrfu/tinyTPU/)

## Status

The core has been completed and successfully passes simulations as of 2024-10-12.

### Next Steps

- Integration of an AXI module for communication
- Evaluation on real hardware with actual machine learning workloads
- Refinement of the hardware description
- Enhancement of the documentation

## Contributing

Contributions of any kind are welcome. If you encounter a bug, please do not hesitate to create an issue.

## License

MIT License