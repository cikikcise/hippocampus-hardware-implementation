# FPGA Implementation of a Hippocampus

This repository contains the Verilog source code for the hardware implementation of a three-layer Spiking Neural Network (SNN) on a Xilinx Virtex-6 FPGA.

## Overview

The design implements a digital SNN with the following characteristics:
* **Neuron Model:** Leaky Integrate-and-Fire (LIF) model, including digital computation of the leak current.
* **Learning Mechanism:** Spike-Timing-Dependent Plasticity (STDP). The weight updates are managed that operates within specific pre- and post-synaptic spike timing windows.

## Repository Structure

* `/src`: Verilog (`.v`) source files including:
  * LIF neuron model
  * Synapse modules
  * STDP learning module and FSM controller
  * Exponential function and adder modules
* `/tb`: Testbench files for behavioral simulation.
* `/constraints`: Timing and physical constraint files for the Virtex-6 implementation.

## Environment

* **Target Hardware:** Xilinx Virtex-6 FPGA
* **Language:** Verilog HDL


