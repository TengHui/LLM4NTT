# -*- coding: utf-8 -*-
import random
import math

class PrimeGenerator:
    """
    Class for generating large prime numbers using the Miller-Rabin primality test.
    Optimized to reduce unnecessary checks and generate only odd candidates.
    """
    
    LOW_PRIMES = [
        3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79,
        83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163,
        167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241,
        251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337,
        347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431,
        433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521,
        523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617,
        619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701, 709, 719,
        727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823,
        827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929,
        937, 941, 947, 953, 967, 971, 977, 983, 991, 997
    ]
    
    def __init__(self, security_level=11):
        """
        Initialize the PrimeGenerator with a specified security level.
        
        Args:
            security_level (int): Number of iterations in the Miller-Rabin test.
                                  Higher values increase accuracy but increase runtime.
                                  Default is 11 which gives < 2^-80 error probability.
        """
        self.security_level = security_level
    
    def is_prime(self, n):
        """
        Check if a number n is prime using trial division for small primes and Miller-Rabin.
        
        Args:
            n (int): Number to test for primality.
            
        Returns:
            bool: True if n is likely prime, False otherwise.
        """
        if n <= 1:
            return False
        if n <= 3:
            return True  # 2 and 3 are primes
        if n % 2 == 0:
            return False  # Eliminate even numbers > 3
        
        # Check divisibility by small primes
        for p in self.LOW_PRIMES:
            if n == p:
                return True
            if n % p == 0:
                return False
        
        return self._miller_rabin(n)
    
    def _miller_rabin(self, n):
        """
        Perform the Miller-Rabin primality test on n.
        
        Args:
            n (int): Number to test for primality.
            
        Returns:
            bool: True if n passes all Miller-Rabin tests, False if composite.
        """
        # Express n-1 as d * 2^s
        d = n - 1
        s = 0
        while (d % 2) == 0:
            d //= 2
            s += 1
        
        # Perform Miller-Rabin tests
        for _ in range(self.security_level):
            a = random.randint(2, n - 2)
            x = pow(a, d, n)
            
            if x == 1 or x == n - 1:
                continue
            
            for _ in range(s - 1):
                x = pow(x, 2, n)
                if x == n - 1:
                    break
            else:
                # If no break occurred, n is composite
                return False
        
        return True
    
    def generate_large_prime(self, bit_length):
        """
        Generate a large prime number with specified bit length.
        
        Args:
            bit_length (int): Desired bit length of the prime number.
            
        Returns:
            int: A large prime number with the specified bit length.
            
        Raises:
            ValueError: If bit_length is less than 2.
            RuntimeError: If a prime cannot be found within the allowed attempts.
        """
        if bit_length < 2:
            raise ValueError("bit_length must be at least 2")
        
        # Calculate maximum attempts based on bit length complexity
        attempts = int(100 * (math.log(bit_length, 2) + 1))
        
        # Define range bounds for odd numbers only
        start = (1 << (bit_length - 1)) | 1  # First odd number in range
        end = (1 << bit_length) - 1          # Max value for bit_length bits
        
        # Generate random odd numbers and test for primality
        for _ in range(attempts):
            n = random.randrange(start, end + 1, 2)  # Step=2 ensures odd numbers
            if self.is_prime(n):
                return n
        
        raise RuntimeError(f"Failed to generate a {bit_length}-bit prime after {attempts} attempts")

# Example usage
if __name__ == "__main__":
    generator = PrimeGenerator()
    
    # Test different bit lengths
    for bits in [8, 16, 32, 64, 128, 256, 512]:
        try:
            prime = generator.generate_large_prime(bits)
            print(f"Generated {bits}-bit prime: {prime}")
        except Exception as e:
            print(f"Error generating {bits}-bit prime: {e}")