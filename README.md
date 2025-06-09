# NTT/INTT Test Data Generator and Validator

This repository provides a comprehensive test environment for Number Theoretic Transform (NTT) and Inverse NTT (INTT) implementations. It includes scripts for generating test data, parameters, and validating NTT/INTT results. The tool is particularly useful for hardware implementation verification and algorithm testing.

## Table of Contents
- [File Structure](#file-structure)
- [Parameters](#parameters)
  - [User-Defined Parameters](#user-defined-parameters)
  - [Pre-defined Parameters](#pre-defined-parameters)
- [Usage and Commands](#usage-and-commands)
  - [Basic Usage Flow](#basic-usage-flow)
  - [Parameter Customization](#parameter-customization)
  - [Available Commands](#available-commands)
- [Generated Files](#generated-files)
  - [Parameter Generation](#parameter-generation-make-params)
  - [NTT Data Generation](#ntt-data-generation-make-ntt-gen)
  - [INTT Data Generation](#intt-data-generation-make-intt-gen)
- [Test Requirements](#test-requirements)
  - [NTT Test](#ntt-test-make-ntt-test)
  - [INTT Test](#intt-test-make-intt-test)

## File Structure

- `Test.py`: Main test file containing parameter generation and test functions
- `NTT.py`: Core NTT implementation with forward and inverse transforms
- `PrimeGenerator.py`: Utility for generating large prime numbers
- `Makefile`: Build automation for testing and parameter generation
- `files/`: Directory containing generated test data and parameters

## Parameters

### User-Defined Parameters

The following parameters can be modified in the `Test.py` file:

- `PC` (Parameter Control): 
  - `0`: Generate new parameters
  - `1`: Use pre-defined parameters

- `N` (Transform Size): 
  - Size of the transform (must be a power of 2)
  - Default: 1024

- `K` (Bit Length): 
  - Bit length for prime generation
  - Default: 32

- `P` (Processing Elements): 
  - Number of parallel processing elements
  - Default: 8

### Pre-defined Parameters

The pre-defined parameters in `pre_defined_params` are:
```python
pre_defined_params = (1024, 32, 2600685569, 5287415)
```

Where:
1. `1024`: Transform size (N)
2. `32`: Bit length (K)
3. `2600685569`: Prime modulus (q)
4. `5287415`: Primitive root (psi)

## Usage and Commands

The project provides several make commands for different operations. Note that `ntt-gen` and `intt-gen` commands will automatically generate parameters if they don't exist.

### Basic Usage Flow

1. Generate test data (parameters will be automatically generated if needed):
```bash
make ntt-gen    # Generate NTT test data
make intt-gen   # Generate INTT test data
```

2. Run tests:
```bash
make ntt-test
make intt-test
```

3. Clean generated files:
```bash
make clean
```

### Parameter Customization

To use custom parameters:
1. Set `PC = 1` in `Test.py`
2. Modify the `pre_defined_params` tuple with your desired values:
```python
pre_defined_params = (N, K, q, psi)  # Replace with your values
```

### Available Commands

- `make params`: Generate NTT parameters
  - Creates PARAM.txt with all necessary parameters for NTT operations
  - Note: This is automatically called by `ntt-gen` and `intt-gen` if parameters don't exist

- `make ntt-gen`: Generate NTT test data
  - Automatically generates parameters if they don't exist
  - Creates input/output files for NTT operations
  - Generates twiddle factors

- `make intt-gen`: Generate INTT test data
  - Automatically generates parameters if they don't exist
  - Creates input/output files for INTT operations
  - Generates inverse twiddle factors

- `make ntt-test`: Test NTT results
  - Compares NTT output with expected results
  - Verifies correctness of NTT implementation

- `make intt-test`: Test INTT results
  - Compares INTT output with expected results
  - Verifies correctness of INTT implementation

- `make clean`: Clean generated files
  - Removes all generated .txt files from the files directory

- `make help`: Display help information
  - Shows available make commands and their descriptions

## Generated Files

After running the data generation commands, the following files will be created in the `files/` directory:

### Parameter Generation (`make params`)
- `PARAM.txt`: Contains all NTT parameters in hexadecimal format
  - N: Transform size
  - q: Prime modulus
  - w: Primitive root
  - w_inv: Inverse primitive root
  - psi: NTT primitive root
  - psi_inv: Inverse NTT primitive root
  - n_inv: Inverse of N modulo q
  - R: Montgomery constant

### NTT Data Generation (`make ntt-gen`)
- `NTT_DIN.txt`: Input data for NTT in hexadecimal format
- `NTT_DOUT.txt`: Expected output data for NTT in hexadecimal format
- `W.txt`: Twiddle factors for NTT in hexadecimal format

### INTT Data Generation (`make intt-gen`)
- `INTT_DIN.txt`: Input data for INTT in hexadecimal format
- `INTT_DOUT.txt`: Expected output data for INTT in hexadecimal format
- `WINV.txt`: Twiddle factors for INTT in hexadecimal format

## Test Requirements

To run NTT/INTT tests, you need to provide result files that will be compared with the expected outputs:

### NTT Test (`make ntt-test`)
- Required file: `files/NTT_RES.txt`
  - Contains the NTT results in hexadecimal format
  - One value per line
  - Values should be the final stage results without bit-reversal
  - Example format:
    ```
    1a2b3c4d
    5e6f7g8h
    ...
    ```

### INTT Test (`make intt-test`)
- Required file: `files/INTT_RES.txt`
  - Contains the INTT results in hexadecimal format
  - One value per line
  - Values should be the final stage results without bit-reversal
  - Example format:
    ```
    1a2b3c4d
    5e6f7g8h
    ...
    ```

Note: The test results should be in hexadecimal format with one value per line, representing the final stage results without any bit-reversal permutation. The values should match the expected outputs in `NTT_DOUT.txt` and `INTT_DOUT.txt` respectively. 