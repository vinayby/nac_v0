# Fitter

## Dependencies
### Gurobi
```bash
cd gurobi751/linux64/
python setup.py build 
python setup.py build and install --user

# ~/.bashrc
export GUROBI_HOME=/opt/gurobi751/linux64
export PATH="${PATH}:${GUROBI_HOME}/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
export GRB_LICENSE_FILE='/opt/gurobi751/linux64/gurobi.lic'
```


