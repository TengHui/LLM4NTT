#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import math
import random
import argparse
from NTT import NTT
from PrimeGenerator import PrimeGenerator

def generate_parameters(N, K, P, PC=0, pre_defined_params=None):
    """
    Generate or use pre-defined parameters for NTT operations.
    
    Args:
        N (int): Size of the transform
        K (int): Bit length for prime generation
        P (int): Number of processing elements
        PC (int): 0 for generating parameters, 1 for using pre-defined
        pre_defined_params (tuple): Pre-defined parameters (N, K, q, psi)
    
    Returns:
        tuple: All generated parameters
    """
    if PC and pre_defined_params:
        N, K, q, psi = pre_defined_params
    else:
        prime_gen = PrimeGenerator()
        while True:
            q = prime_gen.generate_large_prime(K)
            if (q % (2*N)) == 1:
                break
        
        # Generate NTT parameters
        for i in range(2, q-1):
            if pow(i, 2*N, q) == 1:
                if pow(i, N, q) == (q-1):
                    pru = [pow(i, x, q) for x in range(1, 2*N)]
                    if 1 not in pru:
                        psi = i
                        break
    
    # Create NTT instance for parameter calculations
    ntt = NTT(P=q, W=psi, W_inv=psi)
    psi_inv = ntt._modinv(psi, q)
    w = pow(psi, 2, q)
    w_inv = ntt._modinv(w, q)
    R = 2**((int(math.log2(N))+1) * int(math.ceil((1.0*K)/(1.0*((int(math.log2(N))+1))))))
    n_inv = ntt._modinv(N, q)

    # Print parameters
    print("-----------------------")
    print("N      : {}".format(N))
    print("K      : {}".format(K))
    print("P      : {}".format(P))
    print("q      : {}".format(q))
    print("psi    : {}".format(psi))
    print("psi_inv: {}".format(psi_inv))
    print("w      : {}".format(w))
    print("w_inv  : {}".format(w_inv))
    print("n_inv  : {}".format(n_inv))
    print("log(R) : {}".format(int(math.log(R,2))))
    print("-----------------------")
    
    # Write parameters to file
    with open("test/PARAM.txt", "w") as f:
        f.write(f"{hex(N)[2:].ljust(20)}\n")
        f.write(f"{hex(K)[2:].ljust(20)}\n")
        f.write(f"{hex(P)[2:].ljust(20)}\n")
        f.write(f"{hex(q)[2:].ljust(20)}\n")
        f.write(f"{hex(psi)[2:].ljust(20)}\n")
        f.write(f"{hex(psi_inv)[2:].ljust(20)}\n")
        f.write(f"{hex(w)[2:].ljust(20)}\n")
        f.write(f"{hex(w_inv)[2:].ljust(20)}\n")
        f.write(f"{hex((n_inv*R)%q)[2:].ljust(20)}\n")
        f.write(f"{hex(R)[2:].ljust(20)}\n")
    
    return {"N": N, "K": K, "P": P, "q": q, "psi": psi, "psi_inv": psi_inv, "w": w, "w_inv": w_inv, "n_inv": n_inv, "R": R}

def generate_ntt_data(N, q, w, w_inv, P, R):
    """
    Generate NTT input/output data and twiddle factors.
    
    Args:
        N (int): Size of the transform
        q (int): Prime modulus
        w (int): Primitive root
        R (int): Montgomery constant
    """
    # Generate random input data
    A = [random.randint(0, q-1) for _ in range(N)]
    
    # Perform NTT using NTT class
    ntt = NTT(P=q, W=w, W_inv=w_inv)
    A_ntt = ntt.forward_ntt(A)
    A_rev = ntt.index_reverse(A_ntt)
    
    # Write input/output data
    with open("test/NTT_DIN.txt", "w") as f:
        for x in A:
            f.write(f"{hex(x)[2:]}\n")
    
    with open("test/NTT_DOUT.txt", "w") as f:
        for x in A_ntt:
            f.write(f"{hex(x)[2:]}\n")
    
    # Write twiddle factors
    with open("test/W.txt", "w") as f, open("test/WINV.txt", "w") as finv:
        for j in range(int(math.log2(N))):
            for k in range(max(1, (N//(P*2**j)))):
                for i in range(P):
                    w_pow = (((P<<j)*k + (i<<j)) % (N//2))
                    f.write(f"{hex(((pow(w, w_pow, q) * R) % q))[2:]}\n")
                    finv.write(f"{hex(((pow(w_inv, w_pow, q) * R) % q))[2:]}\n")

def generate_intt_data(N, q, w, w_inv, P, R):
    """
    Generate INTT input/output data and twiddle factors.
    
    Args:
        N (int): Size of the transform
        q (int): Prime modulus
        w_inv (int): Inverse primitive root
        R (int): Montgomery constant
    """
    # Generate random input data
    A = [random.randint(0, q-1) for _ in range(N)]
    
    # Perform INTT using NTT class
    ntt = NTT(P=q, W=w, W_inv=w_inv)
    A_intt = ntt.inverse_ntt(A)
    A_rev = ntt.index_reverse(A_intt)
    
    # Write input/output data
    with open("test/INTT_DIN.txt", "w") as f:
        for x in A:
            f.write(f"{hex(x)[2:]}\n")
    
    with open("test/INTT_DOUT.txt", "w") as f:
        for x in A_intt:
            f.write(f"{hex(x)[2:]}\n")
    
    # Write twiddle factors
    with open("test/W.txt", "w") as f, open("test/WINV.txt", "w") as finv:
        for j in range(int(math.log2(N))):
            for k in range(max(1, (N//(P*2**j)))):
                for i in range(P):
                    w_pow = (((P<<j)*k + (i<<j)) % (N//2))
                    f.write(f"{hex(((pow(w, w_pow, q) * R) % q))[2:]}\n")
                    finv.write(f"{hex(((pow(w_inv, w_pow, q) * R) % q))[2:]}\n")

def test_ntt_results():
    """
    Test NTT results by comparing NTT_DOUT.txt with NTT_RES.txt
    """
    try:
        with open("test/NTT_DOUT.txt", "r") as f1, open("test/NTT_RES.txt", "r") as f2:
            expected = [int(line.strip(), 16) for line in f1]
            actual = [int(line.strip(), 16) for line in f2]
            
            if len(expected) != len(actual):
                print("Error: Length mismatch in NTT results")
                return False
            
            for i, (exp, act) in enumerate(zip(expected, actual)):
                if exp != act:
                    print(f"Error: Mismatch at position {i+1}")
                    print(f"Expected: {hex(exp)}, Got: {hex(act)}")
                    return False
            
            print("NTT Test: PASSED")
            return True
    except FileNotFoundError:
        print("Error: Required files not found")
        return False

def test_intt_results():
    """
    Test INTT results by comparing INTT_DOUT.txt with INTT_RES.txt
    """
    try:
        with open("test/INTT_DOUT.txt", "r") as f1, open("test/INTT_RES.txt", "r") as f2:
            expected = [int(line.strip(), 16) for line in f1]
            actual = [int(line.strip(), 16) for line in f2]
            
            if len(expected) != len(actual):
                print("Error: Length mismatch in INTT results")
                return False
            
            for i, (exp, act) in enumerate(zip(expected, actual)):
                if exp != act:
                    print(f"Error: Mismatch at position {i+1}")
                    print(f"Expected: {hex(exp)}, Got: {hex(act)}")
                    return False
            
            print("INTT Test: PASSED")
            return True
    except FileNotFoundError:
        print("Error: Required files not found")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='NTT Test Generator')
    parser.add_argument('--params', action='store_true', help='Generate parameters')
    parser.add_argument('--ntt-gen', action='store_true', help='Generate NTT data')
    parser.add_argument('--intt-gen', action='store_true', help='Generate INTT data')
    parser.add_argument('--ntt-test', action='store_true', help='Test NTT results')
    parser.add_argument('--intt-test', action='store_true', help='Test INTT results')
    
    args = parser.parse_args()
    
    # User self-define parameters
    PC = 0
    N = 1024
    K = 16
    P = 8

    # Default pre-defined parameters
    pre_defined_params = (1024, 32, 2600685569, 5287415)
    
    if args.params:
        params = generate_parameters(N, K, P, PC, pre_defined_params)
        print("Parameters generated successfully")
    
    if args.ntt_gen:
        params = generate_parameters(N, K, P, PC, pre_defined_params)
        generate_ntt_data(params["N"], params["q"], params["w"], params["w_inv"], params["P"], params["R"])
        print("NTT data generated successfully")
    
    if args.intt_gen:
        params = generate_parameters(N, K, P, PC, pre_defined_params)
        generate_intt_data(params["N"], params["q"], params["w"], params["w_inv"], params["P"], params["R"])
        print("INTT data generated successfully")
    
    if args.ntt_test:
        test_ntt_results()
    
    if args.intt_test:
        test_intt_results() 