# -*- coding: utf-8 -*-
import math
import random

class NTT:
    """
    Class for performing Number Theoretic Transform (NTT) and its inverse (INTT)
    using iterative Cooley-Tukey algorithm with decimation in frequency.

    Attributes:
        P (int): Prime modulus for modular arithmetic
        W (int): Primitive root modulo P for forward transform
        W_inv (int): Inverse primitive root modulo P for inverse transform
    """

    def __init__(self, P, W, W_inv):
        """
        Initialize NTT transformer with modular parameters.

        Args:
            P (int): Prime modulus for modular arithmetic
            W (int): Primitive root modulo P for forward transform
            W_inv (int): Inverse primitive root modulo P for inverse transform
        """
        self.P = P
        self.W = W
        self.W_inv = W_inv

    def forward_ntt(self, arrayIn):
        """
        Perform iterative forward NTT on input array.

        Args:
            arrayIn (list): Input array of length N=2^n

        Returns:
            list: NTT transformed array in bit-reversed order

        Raises:
            ValueError: If input length is not a power of two
        """
        N = len(arrayIn)
        if N & (N - 1) != 0:
            raise ValueError("Input length must be a power of two")

        arrayOut = arrayIn.copy()
        v = int(math.log2(N))

        for i in range(v):
            for j in range(1 << i):
                for k in range(1 << (v - i - 1)):
                    s = j * (1 << (v - i)) + k
                    t = s + (1 << (v - i - 1))
                    exponent = (1 << i) * k
                    w = pow(self.W, exponent, self.P)

                    as_temp = arrayOut[s]
                    at_temp = arrayOut[t]

                    arrayOut[s] = (as_temp + at_temp) % self.P
                    arrayOut[t] = ((as_temp - at_temp) * w) % self.P

        return arrayOut

    def inverse_ntt(self, arrayIn):
        """
        Perform iterative inverse NTT on input array.

        Args:
            arrayIn (list): Input array in bit-reversed order

        Returns:
            list: Reconstructed array in normal order

        Raises:
            ValueError: If input length is not a power of two
        """
        N = len(arrayIn)
        if N & (N - 1) != 0:
            raise ValueError("Input length must be a power of two")

        arrayOut = arrayIn.copy()
        v = int(math.log2(N))
        N_inv = self._modinv(N, self.P)

        for i in range(v):
            for j in range(1 << i):
                for k in range(1 << (v - i - 1)):
                    s = j * (1 << (v - i)) + k
                    t = s + (1 << (v - i - 1))
                    exponent = (1 << i) * k
                    w = pow(self.W_inv, exponent, self.P)

                    as_temp = arrayOut[s]
                    at_temp = arrayOut[t]

                    arrayOut[s] = (as_temp + at_temp) % self.P
                    arrayOut[t] = ((as_temp - at_temp) * w) % self.P

        return [(x * N_inv) % self.P for x in arrayOut]

    def index_reverse(self, array):
        """
        Reorder array elements according to bit-reversed indices.

        Args:
            array (list): Input array of length N=2^n

        Returns:
            list: Array with elements reordered by bit-reversed indices
        """
        N = len(array)
        v = int(math.log2(N))
        reversed_array = [0] * N

        for i in range(N):
            rev_idx = self._reverse_bits(i, v)
            reversed_array[rev_idx] = array[i]

        return reversed_array

    def _reverse_bits(self, num, n_bits):
        """Reverse the bit order of an integer."""
        bin_str = bin(num)[2:].zfill(n_bits)
        return int(bin_str[::-1], 2)

    def _modinv(self, a, m):
        """Compute modular inverse using extended Euclidean algorithm."""
        g, x, y = self._egcd(a, m)
        if g != 1:
            raise ValueError("Modular inverse does not exist")
        return x % m

    def _egcd(self, a, b):
        """Extended Euclidean algorithm."""
        if a == 0:
            return (b, 0, 1)
        else:
            g, y, x = self._egcd(b % a, a)
            return (g, x - (b // a) * y, y)

# Test example
if __name__ == "__main__":
    # Parameters from specification
    N = 1024
    K = 32
    q = 2600685569
    w = 1988201044
    w_inv = 1944870590

    # Initialize NTT transformer
    ntt = NTT(P=q, W=w, W_inv=w_inv)

    # Generate random test data
    A = [random.randint(0, q-1) for _ in range(N)]
    print("Input array (first 5 elements):", A[:5])

    # Forward NTT
    A_ntt = ntt.forward_ntt(A)
    print("NTT result (first 5 elements):", A_ntt[:5])
    
    # Bit reverse NTT result
    A_rev = ntt.index_reverse(A_ntt)
    print("Index-reversed NTT result (first 5 elements):", A_rev[:5])
    
    # Inverse NTT
    A_rec = ntt.inverse_ntt(A_rev)
    print("INTT result (first 5 elements):", A_rec[:5])
    
    # Bit reverse INTT result
    A_res = ntt.index_reverse(A_rec)
    print("Index-reversed INTT result (first 5 elements):", A_res[:5])

    # Verify correctness
    if all((a - a_res) % q == 0 for a, a_res in zip(A, A_res)):
        print("Sanity Check: NTT operation is correct.")
    else:
        print("Sanity Check: Check your math with NTT/INTT operation.")