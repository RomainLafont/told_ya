# told_ya

Project for Starkhack 2024

## Test / deploy

### Requirements

Requirements:

- scarb 2.6.3 (e6f921dfd 2024-03-13)
- cairo: 2.6.3 ([https://crates.io/crates/cairo-lang-compiler/](https://crates.io/crates/cairo-lang-compiler/))
- sierra: 1.5.0
- make (gcc)
- starkli: 0.2.9
- katana: 0.7.2 (dev dependency)

### Setup

Install the requirements:

```bash
make setup-unix
```

### Commands

Run devnet:

```bash
make run-network
```

In another terminal window, declare and deploy on devnet:

```bash
make contract-full
```
