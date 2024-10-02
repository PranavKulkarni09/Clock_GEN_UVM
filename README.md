# Clock_GEN_UVM
The Clock Generator module (clk_gen) produces a transmission clock (tx_clk) from a system clock (clk) based on a selected baud rate. The baud rate determines how frequently the tx_clk toggles relative to the system clock.

# Verification Approach
The project implements UVM for verifying the clk_gen module. UVM is an industry-standard methodology for building reusable and scalable testbenches for digital designs.

# # Key Components of the UVM Testbench:
- # Transaction:
- Defines the operation (reset or random baud rate change) and the baud rate value.
Randomized to test the design with different baud rate settings.
- # Driver:
- Drives signals to the clk_gen DUT (Device Under Test), sending either reset or baud rate change commands.
- # Monitor:
- Observes the DUT's behavior by tracking the generated tx_clk signal and measuring the clock period.
- # Scoreboard:
- Compares the observed clock period with expected values based on the baud rate to determine if the design is functioning correctly.
- # Sequences:
- Two sequences (reset_clk and variable_baud) generate test scenarios, including resets and random baud rate changes, to verify the design's robustness.
- # Agent:
- Manages the driver, monitor, and sequencer components, encapsulating their functionalities into a reusable unit.
- # Environment:
- The UVM environment (env) integrates the agent and the scoreboard. It connects the monitor's output to the scoreboard for checking the correctness of the results.
- # Test:
- The top-level UVM test class, which executes the sequences to verify the clock generator behavior.
