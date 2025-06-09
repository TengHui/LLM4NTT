.PHONY: params ntt-gen intt-gen ntt-test intt-test clean help

# Generate parameters
params:
	python3 Test.py --params

# Generate NTT data
ntt-gen:
	python3 Test.py --ntt-gen

# Generate INTT data
intt-gen:
	python3 Test.py --intt-gen

# Test NTT results
ntt-test:
	python3 Test.py --ntt-test

# Test INTT results
intt-test:
	python3 Test.py --intt-test

# Clean all data files
clean:
	rm test/*.txt

# Help target
help:
	@echo "Available targets:"
	@echo "  make params         - Generate parameters"
	@echo "  make ntt-gen        - Generate NTT data"
	@echo "  make intt-gen       - Generate INTT data"
	@echo "  make ntt-test       - Test NTT results"
	@echo "  make intt-test      - Test INTT results"
	@echo "  make clean          - Clean all txt files"