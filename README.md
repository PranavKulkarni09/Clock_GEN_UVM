# Clock_GEN_UVM
The Clock Generator module (clk_gen) produces a transmission clock (tx_clk) from a system clock (clk) based on a selected baud rate. The baud rate determines how frequently the tx_clk toggles relative to the system clock.

# Verification Approach
The project implements UVM for verifying the clk_gen module. UVM is an industry-standard methodology for building reusable and scalable testbenches for digital designs.

# # Key Components of the UVM Testbench:
- # Transaction:
- Keeps track of all the input and output present in the DUT.
- Randomized to test the design with different baud rate settings.
- # Driver:
- Drives signals to the clk_gen DUT (Design Under Test), in this case sending either reset or baud rate change commands.
- # Monitor:
- Observes the DUT's behavior by tracking the generated signals and measuring the clock period, It also forwards the data to scoreboard.
- # Scoreboard:
- Compares the data from monitor with expected values based on the baud rate to determine if the design is functioning correctly.
- # Sequences:
- Two sequences (reset_clk and variable_baud) generate test scenarios, including reset and random baud rate cases, to verify the design's robustness.
- It is basically the combination of transactions to verify a specific test case.
- # Agent:
- Encapsulates Driver, Sequencer, and Monitor while managing the connection of Driver and Sequecer TLM ports.
- # Environment:
- Encapsulates Agent, Scoreboard, and connection of analysis port of monitor and scoreboard.
- The UVM environment (env) integrates the agent and the scoreboard. It connects the monitor's output to the scoreboard for checking the correctness of the results.
- # Test:
- The top-level UVM test class, which executes the sequences to verify the clock generator behavior and also encapsulates Environment.
