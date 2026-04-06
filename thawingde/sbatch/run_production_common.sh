#!/bin/bash
set -euo pipefail

#
# Shared runtime body for the production thawing-model runs.
# Sources for this launch pattern:
# - /Users/joannjones/Desktop/clusterarc/sbatch-files/thawing.sbatch
# - /Users/joannjones/Desktop/clusterarc/sbatch-files/plancksptact.sbatch
#
# Fixed cluster location provided by the user:
#   /project/sdodelso/joannjones/cosmosis-standard-library
#
# Required per-wrapper variable:
#   RUN_INI
#
# Optional override:
#   THAW_CAMB_PYTHONPATH
#

: "${RUN_INI:?Wrapper must export RUN_INI before sourcing run_production_common.sh.}"

export CSL_DIR="${CSL_DIR:-/project/sdodelso/joannjones/cosmosis-standard-library}"

source ~/miniforge3/etc/profile.d/conda.sh
conda activate cosmosis_thaw

# Make the conda-provided GSL visible to ctypes-loaded modules.
export GSL_LIB="${GSL_LIB:-${CONDA_PREFIX}/lib}"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
# Expose Planck clik C library required by planck_interface.so
export LD_LIBRARY_PATH="${CSL_DIR}/likelihood/planck2018/plc-3.0/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"


# Prevent site/user packages or a stale CAMB install from leaking into the job.
export PYTHONNOUSERSITE=1
unset PYTHONPATH

cd "${CSL_DIR}"

mkdir -p thawingde/chains/external
mkdir -p thawingde/chains/3x2
mkdir -p thawingde/chains/cmb
mkdir -p thawingde/chains/joint
mkdir -p thawingde/chains/cmb_joint
mkdir -p thawingde/chains/logs

set +u
source cosmosis-configure
set -u

echo "CONDA_PREFIX=${CONDA_PREFIX}"
echo "GSL_LIB=${GSL_LIB:-}"
if [[ -z "${GSL_LIB:-}" ]]; then
    echo "GSL_LIB is not set after environment setup." >&2
    exit 1
fi

if [[ ! -f "${GSL_LIB}/libgsl.so" || ! -f "${GSL_LIB}/libgslcblas.so" ]]; then
    echo "Expected GSL shared libraries under ${GSL_LIB}, but they were not found." >&2
    ls -l "${GSL_LIB}"/libgsl* "${GSL_LIB}"/libgslcblas* 2>/dev/null || true
    exit 1
fi

python -c "import ctypes as ct, os; ct.CDLL(os.path.join(os.environ['GSL_LIB'], 'libgsl.so'), mode=ct.RTLD_GLOBAL); ct.CDLL(os.path.join(os.environ['GSL_LIB'], 'libgslcblas.so'), mode=ct.RTLD_GLOBAL); print('GSL preload ok')"



# Keep the ACT path available in the same way as the working thawing job.
export PYTHONPATH="$PWD/likelihood/act-dr6-lite/external/DR6-ACT-lite${PYTHONPATH:+:${PYTHONPATH}}"
export COSMOSIS_STANDARD_LIBRARY="$PWD"

# Match the hacked-CAMB injection used by the working thawing job.
export THAW_CAMB_PYTHONPATH="${THAW_CAMB_PYTHONPATH:-/project/sdodelso/joannjones/thaw_camb}"
export PYTHONPATH="${THAW_CAMB_PYTHONPATH}${PYTHONPATH:+:${PYTHONPATH}}"


if [[ ! -f "${RUN_INI}" ]]; then
    echo "RUN_INI not found under ${CSL_DIR}: ${RUN_INI}" >&2
    exit 1
fi

export N_JOBS="${SLURM_NTASKS:-1}"
export N_BATCH="${N_BATCH:-$(( N_JOBS * 5 ))}"
export OMP_NUM_THREADS=1

which mpirun
mpirun --version
which cosmosis
python -c "import sys; print('python:', sys.executable)"
python -c "import camb; print('CAMB:', camb.__file__)"

echo "starting CosmoSIS using $SLURM_NTASKS MPI ranks"
mpirun -n "${SLURM_NTASKS:-2}" "$CONDA_PREFIX/bin/cosmosis" --mpi "${RUN_INI}"

if [[ -n "${EXPORT_SN_DISTANCES_CHAIN:-}" && -n "${EXPORT_SN_DISTANCES_OUTPUT:-}" ]]; then
    echo "exporting plot-ready SN distances from ${EXPORT_SN_DISTANCES_CHAIN}"
    python thawingde/tools/export_sn_distances.py \
        --chain "${EXPORT_SN_DISTANCES_CHAIN}" \
        --output "${EXPORT_SN_DISTANCES_OUTPUT}" \
        --camb-path "${THAW_CAMB_PYTHONPATH}"
fi