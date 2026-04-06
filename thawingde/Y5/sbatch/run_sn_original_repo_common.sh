#!/bin/bash
set -euo pipefail

: "${RUN_INI:?Wrapper must export RUN_INI before sourcing this script.}"

export CSL_DIR="${CSL_DIR:-/project/sdodelso/joannjones/cosmosis-standard-library}"
export THAW_CAMB_PYTHONPATH="${THAW_CAMB_PYTHONPATH:-/project/sdodelso/joannjones/thaw_camb}"

source ~/miniforge3/etc/profile.d/conda.sh
conda activate cosmosis_thaw

# Keep the environment deterministic and force hacked CAMB first.
export PYTHONNOUSERSITE=1
unset PYTHONPATH

export GSL_LIB="${GSL_LIB:-${CONDA_PREFIX}/lib}"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

cd "${CSL_DIR}"
mkdir -p thawingde/Y5/chains

# cosmosis-configure probes shell vars that may be unset under strict nounset.
set +u
source cosmosis-configure
set -u

export COSMOSIS_STANDARD_LIBRARY="$PWD"
export PYTHONPATH="$PWD/likelihood/act-dr6-lite/external/DR6-ACT-lite"
export PYTHONPATH="${THAW_CAMB_PYTHONPATH}:${PYTHONPATH}"

export OMP_NUM_THREADS=1

python -c "import sys; print('python:', sys.executable)"
python -c "import camb; print('CAMB:', camb.__file__)"

mpirun -n "${SLURM_NTASKS:-2}" "$CONDA_PREFIX/bin/cosmosis" --mpi "${RUN_INI}"
