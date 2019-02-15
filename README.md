# NAC (NA compiler)
* NOTE: This is a very early release. 
* TODO: 
    * Code reorganisation/refactoring (long overdue)
    * Add application examples/notes
    * 

-------------
## Setup

### From source 
```bash
git clone hpc21git:nac  # (Lab/Local) OR
git clone https://github.com/vinayby/nac.git 
```
On the fresh clone, run:

```bash
cd nac/
git submodule update --init --recursive 

pip3 install ply
pip3 install configargparse
pip3 install pyastyle
```
Quick check: `export PATH=$PATH:/path/to/NAC_TOPDIR` and `nac --help`.

A portable 1-file binary executable (`nac`) from the source could now be made (if needed) by running `pyinstaller nac.spec`.
The following additional dependencies are required to use `nac` (even with the 1-file binary).

### Common Dependencies
    
1. Bluespec environment 
    - (with a SceMI license, only for hardware-software co-simulation)
2. Vivado and Vivado\_HLS (*2016.04 recommended*)
3. Miscellaneous
    ```bash
    sudo apt install openmpi-bin 
    sudo apt install libopenmpi-dev
    sudo apt install astyle
    sudo apt install m4
    ```
    
    ```bash
    # ensure sh points to bash
    if [ "$BASH_VERSION" = '' ]; then     
         echo "This is dash, make /bin/sh point to /bin/bash"; 
         echo "sudo update-alternatives --install /bin/sh sh /bin/bash 100 # On Ubuntu" 
    else echo "Ok."; fi
    ```
Optional: for syntax highlighting with `vim` 
```bash
   mkdir -p ~/.vim/
   rsync -av utils/vim/ ~/.vim/
```
Useful VIM plugins:
```
   https://github.com/wincent/command-t
   https://github.com/davidhalter/jedi-vim
   https://github.com/sophacles/vim-bundle-mako
```


### Simulators
The simulators selected (`nac --simulator SIMULATOR`) are used in script-mode.
`Iverilog` and Vivado's own simulator `xsim` could be selected for RTL-only hardware designs, but `Synopsis VCS` has been used for hardware-software simulation.



#### VCS-MX (recommended)

- Lab/Local users may simply copy over `vcs-mx` from `{hpc24, hpc40}:/opt/vM-2017.03/` to their `/opt/`

- $HOME/.bashrc

```bash
    # VCS-MX
    export VCS_HOME=/opt/vM-2017.03
    export PATH=$PATH:${VCS_HOME}/bin
    export LM_LICENSE_FILE=$LM_LICENSE_FILE:27020@10.107.90.16:27000
```

- Xilinx-VCS simlib generation
    - simulation libraries need to be generated for use with VCS
    - on first use, `nac` attempts to generate it, at `$HOME/.config/nac/simlib_vcs/`
        - NOTE: `source /opt/Xilinx/Vivado/2016.4/settings64.sh` once before doing so
    - OR *to generate manually*,
```
        $ source /opt/Xilinx/Vivado/2016.4/settings64.sh
        $ mkdir -p $HOME/.config/nac/simlib_vcs/
        $ vivado -mode tcl
        Vivado% 
        Vivado% compile_simlib -simulator vcs_mx -dir $env(HOME)/.config/nac/simlib_vcs/
```
- Other notes
    - Needs this somewhere during co-sim `sudo apt install libncurses5-dev`
    - <s>vcs is okay with 16.04 gcc-5.4.1 and `ld v2.26`; not okay with `ld v2.28` in 17.04</s> (some checks/workarounds in place) 
    - `vcs` doesn't play well with dash on ubuntu so: 
```
        sudo update-alternatives --install /bin/sh sh /bin/bash 100
```



#### IVERILOG

- Usable for projects that do not involve Vivado HLS IPs/na-kernels.

#### XSIM 

- Limited support for VPI (last checked), but usable with HLS IPs/na-kernels 





## Usage examples

### See [Usage.md](USAGE.md) or [Usage.html](USAGE.html)

## Synthesis

Running `make vivado` from the `sim` folder builds the project and associated
IPs, copies the necessary files to a `stage_sim/` folder and creates a Vivado
project (named `project_1`). 

The synthesis and implementation target VC709's FPGA by default (edit the tcl files to change).
To synthesize and regenerate utilization and timing reports run: `make vivado_synth`. 
To synthesize, implement and regenerate utilization and timing reports run: `make vivado_impl`.
The reports are generated in `../fpga/` folder.

---------------------------------

# NA Fitter 

## Dependencies

- Uses python 2.7 because gurobipy only supports python 3.6 (and no other 3.x) which not yet native to 16.04 
    - (Note: `nac` uses python3)
- Gurobi: [Register](http://www.gurobi.com/registration/general-reg) to download the archive and generate an educational license (node-locked). 

```bash
  # unpack the archive
  cd gurobi751/linux64/ # or gurobi801/linux64
  python setup.py build 
  python setup.py install --user
  
  # may want to (or adjust `.bashrc` appropriately)
  cd ../../
  cp -a gurobi751/linux64 /opt/
```
- ${HOME}/.bashrc
    - (Assuming the paths, and path to the downloaded license file are as below)

```bash
  GUROBI_VERSION=751 # or 801
  export GUROBI_HOME=/opt/gurobi${GUROBI_VERSION}/linux64 
  export PATH="${PATH}:${GUROBI_HOME}/bin"
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
  export GRB_LICENSE_FILE='/opt/gurobi${GUROBI_VERSION}/linux64/gurobi.lic'
```

- Other dependencies

```bash
      pip install networkx --user
      
      sudo apt-get install python-dev graphviz libgraphviz-dev pkg-config 
      
      pip install pygraphviz --user 
      pip install pydotplus --user       # this may have needed libgraphviz-dev
    
      # do above with pip3 too, pyinstaller seems to pick those up by default
      pip3 install pygraphviz --user
      pip3 install pydotplus --user
```
## Usage examples
TODO




# Appendix



## `nac` CLI options

```
usage: nac [-h] -c MY_CONFIG [--noc NOC_BUILDDIR] --outdir OUTDIR
           [--simverbosity {state-entry-exit,state-exit,to-from-network,send-recv-trace}]
           [--simulator SIMULATOR]
           [--simulator-simlib-path SIMULATOR_SIMLIB_PATH]
           [--vhls-kernels-dir VHLS_WRAPPER_OUT_DIR]
           [--kernel-specs-file KERNEL_SPECS_FILE]
           [--bsvwrappers BSV_WRAPPER_OUT_DIR] [--taskmap TASKMAP_JSON_FILE]
           [--buffered-sr-ports] [--scemi] [--no-task-info]
           [--scemi-src-list RT_SRC] [--runtime-data-list RT_DATA]
           [--fnoc-supports-multicast] [--mode-generate-mpi-model]
           [--mpi-src-list MPI_SRC] [--new-tofrom-network]
           [--enable-lateral-bulk-io]
           [--either-or-lateral-io EITHER_OR_LATERAL_IO] [--event-trace]
           nafile


optional arguments:
  -h, --help            show this help message and exit

Core Arguments:
  -c MY_CONFIG, --my-config MY_CONFIG
                        configuration file [with nac options] (default: None)
  nafile                .na application description file
  --noc NOC_BUILDDIR, -n NOC_BUILDDIR
                        path to either of CONNECT or ForthNoC generated NoC
                        build directory (default: None)
  --outdir OUTDIR, -odir OUTDIR
                        path to the work-directory to be generated (default:
                        None)
  --simulator SIMULATOR
                        simulator selection (use vcs or xsim when using HLS
                        kernels, and vcs for hw-sw-scemi simulation) (default:
                        xsim)
  --vhls-kernels-dir VHLS_WRAPPER_OUT_DIR, -hlskernels VHLS_WRAPPER_OUT_DIR
                        directory to both place generated hardware kernel
                        wrappers (C++/Vivado HLS), or to find ready kernels
                        (default: None)
  --kernel-specs-file KERNEL_SPECS_FILE, -kspecs KERNEL_SPECS_FILE
                        Kernel specifications. e.g. Duration (default: None)
  --taskmap TASKMAP_JSON_FILE, -map TASKMAP_JSON_FILE
                        task map .json file (corresponding to the NOC chosen)
                        (default: None)
  --scemi-src-list RT_SRC
                        scemi src list; use cfg file (default: [])
  --runtime-data-list RT_DATA
                        runtime data list; use cfg file (default: None)
  --mode-generate-mpi-model, -mpi
                        generate MPI model for the design entry (with HLS
                        kernels only) (default: False)
  --mpi-src-list MPI_SRC
                        uses the 'host node' source files provided; format
                        nahost_<taskname>.cpp (default: [])

Other Arguments:
  --simverbosity {state-entry-exit,state-exit,to-from-network,send-recv-trace}
                        simulation time verbosity (default: None)
  --simulator-simlib-path SIMULATOR_SIMLIB_PATH
                        (a one-time step) generates simlibs if not present.
                        (default: /home/vinay/.config/nac/simlib_SIMULATOR)
  --bsvwrappers BSV_WRAPPER_OUT_DIR, -bsvwrap BSV_WRAPPER_OUT_DIR
                        directory to place generated BSV kernel wrappers
                        (default: None)
  --buffered-sr-ports   buffer the send-recv ports exposed (TODO use
                        --buffersizingspecs later of this) (default: False)
  --scemi               generate SCEMI stuff (True if scemi_src_list
                        specified) (default: False)
  --no-task-info        do no add an implicit task_info parameters to kernels
                        declarations (default: False)
  --fnoc-supports-multicast
                        specify if the FNOC supports broadcast/multicast
                        feature (default: False)
  --new-tofrom-network, -ntfnw
                        Use the newer version of to-from network (default:
                        False)
  --enable-lateral-bulk-io, -bulkio
                        Export bulk IO ports to external-tasks (default: True)
  --either-or-lateral-io EITHER_OR_LATERAL_IO
  --event-trace, -evts  A markers to record time spent at various places
                        (default: False)
```

# PS: 

This document: Markdown to HTML
```bash
pandoc --self-contained -S --css ./.github-pandoc.css -s -N --toc --toc-depth=4 README.md -o README_generated.html
```
