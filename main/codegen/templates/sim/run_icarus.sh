#!/bin/bash
iverilog *.v -s tb -o a.out && stdbuf -oL -eL vvp -n ./a.out
