#!/bin/bash -fe

# E3SM Water Cycle v2 run_e3sm script template.
#
# Inspired by v1 run_e3sm script as well as SCREAM group simplified run script.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

# TO DO:
# - custom pelayout

main() {

# For debugging, uncomment libe below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=compy
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="F20TR_chemUCI-Linozv3"
readonly RESOLUTION="ne30pg2_EC30to60E2r2"
readonly CASE_NAME="PD.chemUCI_Linozv3_t1.bi-grid"
#readonly CASE_GROUP="v2.LR.chemUCI"

# Code and compilation
readonly CHECKOUT="20220323_amip_update"
readonly BRANCH="tangq/atm/UCI-chem"   #420e251265928a4122a5eb5d4eab4ae8110f84f2 05/172022  
#readonly CHERRY=( "7e4d1c9fec40ce1cf2c272d671f5d9111fa4dea7" "a5b1d42d7cd24924d0dbda95e24ad8d4556d93f1" ) # PR4349
readonly DEBUG_COMPILE=false

# Run options
readonly MODEL_START_TYPE="initial"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="2009-10-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=TRUE
readonly RUN_REFDIR="/compyfs/tang338/E3SM_simulations/20211006.tst_exp/archive/rest/2000-01-01-00000"
readonly RUN_REFCASE="20211006.tst_exp"
readonly RUN_REFDATE="2000-01-01"   # same as MODEL_START_DATE for 'branch', can be different for 'hybrid'

# Set paths
readonly CODE_ROOT="${HOME}/E3SM_code/${CHECKOUT}"
#readonly CODE_ROOT="/qfs/people/tang338/E3SM_code/${CHECKOUT}"
readonly CASE_ROOT="/compyfs/${USER}/E3SM_simulations/${CASE_NAME}"

# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

# Define type of run
#  short tests: 'XS_2x5_ndays', 'XS_1x10_ndays', 'S_1x10_ndays', 
#               'M_1x10_ndays', 'M2_1x10_ndays', 'M80_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation
readonly run='production'
#readonly run='S_1x5_ndays'
if [ "${run}" != "production" ]; then

  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=${tmp[2]}
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=${tmp[1]##*x}

  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  #readonly PELAYOUT=${layout}
  readonly PELAYOUT="custom-10"
  readonly WALLTIME="00:20:00"
  readonly STOP_OPTION=${units}
  readonly STOP_N=${length}
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=${STOP_N}
  readonly RESUBMIT=${resubmit}
  readonly DO_SHORT_TERM_ARCHIVING=false

else

  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  #readonly PELAYOUT="M"
  readonly PELAYOUT="custom-30"
  readonly WALLTIME="10:00:00"
  readonly STOP_OPTION="nmonths"
  readonly STOP_N="15"
  readonly REST_OPTION="nmonths"
  readonly REST_N="3"
  readonly RESUBMIT="0"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler histfalse 
readonly HIST_OPTION="nyears"
readonly HIST_N="2"

# Leave empty (unless you understand what it does)
readonly OLD_EXECUTABLE=""

# --- Toggle flags for what to do ----
do_fetch_code=false
do_create_newcase=true
do_case_setup=true
do_case_build=true
do_case_submit=true

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
fetch_code

# Create case
create_newcase

# Custom PE layout
custom_pelayout

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

readonly new_emis_dir="/compyfs/wumi635/inputdata/cam/chem/emis/CMIP6_emissions_1750_2015_2deg_FINAL"

cat << EOF >> user_nl_eam

nhtfrq = 0,0,-1,-24
mfilt  = 1,1,240,30

 avgflag_pertape = 'A','I','I','A'
 
 fincl1 = 'E90','N2OLNZ','NOYLNZ','H2OLNZ','CH4LNZ','MASS','AREA','TOZ','TROPC_P','TROPC_T','TROPC_Z','TROPS_P','TROPS_T','TROPS_Z','TROPT_P','TROPT_T','TROPT_Z','TROPW_P','TROPW_T','TROPW_Z','TROPH_P','TROPH_T','TROPH_Z','TROPE_P','TROPE_T','TROPE_Z',"O3","OH","HO2","H2O2","NO","NO2","NO3","N2O5","HNO3","HO2NO2","CO","CH2O","CH3O2","CH3OOH","DMS","SO2","ISOP","H2SO4","SOAG","so4_a1","pom_a1","soa_a1","bc_a1 ","dst_a1","ncl_a1","mom_a1","num_a1","so4_a2","soa_a2","ncl_a2","mom_a2","num_a2","dst_a3","ncl_a3","so4_a3","bc_a3","pom_a3","soa_a3","mom_a3","num_a3","pom_a4","bc_a4","mom_a4","num_a4","M_dens","H2O_vmr","CH4","NO_Lightning","NO_Aircraft","CO_Aircraft","CH4_vmr","prsd_ch4","C2H5OOH","CH3CHO",'LNO_COL_PROD','LNO_PROD','PAN','DV_O3','PS','PSDRY','lch4','r_lch4','M_dens','lco_h','r_lco_h','uci1','r_uci1'
 fincl3 = 'O3_SRF'
 fincl4 = 'TCO','SCO','T'

 ncdata		= '/compyfs/tang338/E3SM_simulations/init/tst.20220510.v2.LR.bi-grid.amip.chemUCI_Linozv3.eam.i.2010-01-01-00000.nc'

 !history_gaschmbudget = .true.
 history_gaschmbudget_2D = .true.
 history_gaschmbudget_2D_levels = .true.
 gaschmbudget_2D_L1_s =  1
 gaschmbudget_2D_L1_e = 26
 gaschmbudget_2D_L2_s = 27
 gaschmbudget_2D_L2_e = 38
 gaschmbudget_2D_L3_s = 39
 gaschmbudget_2D_L3_e = 58
 gaschmbudget_2D_L4_s = 59
 gaschmbudget_2D_L4_e = 72
 
 history_UCIgaschmbudget_2D = .true.
 history_UCIgaschmbudget_2D_levels = .true.
 
 linoz_psc_t = 198.0
 tropopause_e90_thrd   = 80.0e-9
 rad_climate           = 'A:H2OLNZ:H2O', 'N:O2:O2', 'N:CO2:CO2',
         'A:O3:O3', 'A:N2OLNZ:N2O', 'A:CH4LNZ:CH4',
         'N:CFC11:CFC11', 'N:CFC12:CFC12', 
         'M:mam4_mode1:${input_data_dir}/atm/cam/physprops/mam4_mode1_rrtmg_aeronetdust_c141106.nc',
         'M:mam4_mode2:${input_data_dir}/atm/cam/physprops/mam4_mode2_rrtmg_c130628.nc', 
         'M:mam4_mode3:${input_data_dir}/atm/cam/physprops/mam4_mode3_rrtmg_aeronetdust_c141106.nc',
         'M:mam4_mode4:${input_data_dir}/atm/cam/physprops/mam4_mode4_rrtmg_c130628.nc'
  ext_frc_type = 'CYCLICAL'
  ext_frc_cycle_yr       = 2010
  srf_emis_specifier             = 'C2H4      -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C2H4_surface_1850-2014_1.9x2.5_c20210323.nc',
         'C2H6      -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C2H6_surface_1850-2014_1.9x2.5_c20210323.nc',
         'C3H8      -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C3H8_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH2O   -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH2O_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH3CHO    -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH3CHO_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH3COCH3  -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH3COCH3_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CO     -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CO_surface_1850-2014_1.9x2.5_c20210323.nc',
         'DMS    -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DMSflux.2010.1deg_latlon_conserv.POPmonthlyClimFromACES4BGC_c20190220.nc',
         'E90       -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions_E90_surface_1750-2015_1.9x2.5_c20210408.nc',
         'ISOP   -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_ISOP_surface_1850-2014_1.9x2.5_c20210323.nc',
         'NO     -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_NO_surface_1850-2014_1.9x2.5_c20210323.nc',
         'SO2    -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so2_surf_1850-2014_c180205.nc',
         'bc_a4  -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_bc_a4_surf_1850-2014_c180205.nc',
         'num_a1 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a1_surf_1850-2014_c180205.nc',
         'num_a2 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a2_surf_1850-2014_c180205.nc',
         'num_a4 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a4_surf_1850-2014_c180205.nc',
         'pom_a4 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_pom_a4_surf_1850-2014_c180205.nc',
         'so4_a1 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a1_surf_1850-2014_c180205.nc',
         'so4_a2 -> /compyfs/inputdata/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a2_surf_1850-2014_c180205.nc'
  srf_emis_type          = 'CYCLICAL'
  srf_emis_cycle_yr      = 2010
!.......................................................
! nudging
!.......................................................
Nudge_Model          = .True.
Nudge_Path           = '/compyfs/zhan524/myinput/ndata/eraint_ne30_pg2L72/'
!'/compyfs/zhan524/myinput/ndata/ndg_eamv2_ne30pg2'
!'/compyfs/zhan524/myinput/ndata/eraint_ne30_pg2L72' 
!'YOUR_NUDGING_DATA' !! my old data are here: /compyfs/zhan524/myinput/ndata/ndg_eamv2_ne30pg2
Nudge_File_Template  = 'eraint_ne30_pg2L72_%y-%m-%d.nc'
!'E3SMv2.eam.h1.%y-%m-%d-00000.nc'
!'eraint_ne30_pg2L72_%y-%m-%d.nc' !'E3SMv2.eam.h1.%y-%m-%d-00000.nc'
Nudge_Times_Per_Day  = 4  !! nudging input data frequency
Model_Times_Per_Day  = 48 !! should not be larger than 48 if dtime = 1800s
Nudge_Uprof          = 2
Nudge_Ucoef          = 1.
Nudge_Vprof          = 2
Nudge_Vcoef          = 1.
Nudge_Tprof          = 0
Nudge_Tcoef          = 0.
Nudge_Qprof          = 0
Nudge_Qcoef          = 0.
Nudge_PSprof         = 0
Nudge_PScoef         = 0.
Nudge_Beg_Year       = 2009 !0001
Nudge_Beg_Month      = 1
Nudge_Beg_Day        = 1
Nudge_End_Year       = 2011 !9999
Nudge_End_Month      = 1
Nudge_End_Day        = 1
Nudge_Vwin_Lindex    = 0.
Nudge_Vwin_Hindex    = 70.
Nudge_Vwin_Ldelta    = 0.1
Nudge_Vwin_Hdelta    = 0.1
Nudge_Vwin_lo        = 0.
Nudge_Vwin_hi        = 1.
Nudge_Method         = 'Linear'
Nudge_Loc_PhysOut    = .True.
Nudge_Tau            = 6.        !! relaxation time scale, unit: 6h
Nudge_CurrentStep    = .False.
Nudge_File_Ntime     = 4

EOF

cat << EOF >> user_nl_elm
 check_finidat_year_consistency = .false.
 check_dynpft_consistency = .false.
 check_finidat_fsurdat_consistency = .false.
 fsurdat = "${input_data_dir}/lnd/clm2/surfdata_map/surfdata_ne30pg2_simyr1850_c210402.nc"
 finidat = '/compyfs/tang338/E3SM_simulations/init/tst.20220510.v2.LR.bi-grid.amip.chemUCI_Linozv3.elm.r.2010-01-01-00000.nc'
EOF

}

# =====================================
# Customize MPAS stream files if needed
# =====================================


patch_mpas_streams() {

echo

}




# =====================================================
# Custom PE layout: custom-N where N is number of nodes
# =====================================================

custom_pelayout() {

if [[ ${PELAYOUT} == custom-* ]];
then
    echo $'\n CUSTOMIZE PROCESSOR CONFIGURATION:'

    # Number of cores per node (machine specific)
    if [ "${MACHINE}" == "chrysalis" ]; then
        ncore=64
    elif [ "${MACHINE}" == "compy" ]; then
        ncore=40
    else
        echo 'ERROR: MACHINE = '${MACHINE}' is not supported for custom PE layout.' 
        exit 400
    fi

    # Extract number of nodes
    tmp=($(echo ${PELAYOUT} | tr "-" " "))
    nnodes=${tmp[1]}

    # Customize
    pushd ${CASE_SCRIPTS_DIR}
    ./xmlchange NTASKS=$(( $nnodes * $ncore ))
    ./xmlchange NTHRDS=1
    ./xmlchange MAX_MPITASKS_PER_NODE=$ncore
    ./xmlchange MAX_TASKS_PER_NODE=$ncore
    popd

fi

}

######################################################
### Most users won't need to change anything below ###
######################################################

#-----------------------------------------------------
fetch_code() {

    if [ "${do_fetch_code,,}" != "true" ]; then
        echo $'\n----- Skipping fetch_code -----\n'
        return
    fi

    echo $'\n----- Starting fetch_code -----\n'
    local path=${CODE_ROOT}
    local repo=e3sm

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .
    
    # Setup git hooks
    rm -rf .git/hooks
    git clone git@github.com:E3SM-Project/E3SM-Hooks.git .git/hooks
    git config commit.template .git/hooks/commit.template

    # Bring in all submodule components
    git submodule update --init --recursive

    # Check out desired branch
    git checkout ${BRANCH}

    # Custom addition
    if [ "${CHERRY}" != "" ]; then
        echo ----- WARNING: adding git cherry-pick -----
        for commit in "${CHERRY[@]}"
        do
            echo ${commit}
            git cherry-pick ${commit}
        done
        echo -------------------------------------------
    fi

    # Bring in all submodule components
    git submodule update --init --recursive

    popd
}

#-----------------------------------------------------
create_newcase() {

    if [ "${do_create_newcase,,}" != "true" ]; then
        echo $'\n----- Skipping create_newcase -----\n'
        return
    fi

    echo $'\n----- Starting create_newcase -----\n'

    if [[ ${PELAYOUT} == custom-* ]];
        then
            layout="M" # temporary placeholder for create_newcase
        else
            layout=${PELAYOUT}
    fi

    if [[ -z "$CASE_GROUP" ]]; then
        ${CODE_ROOT}/cime/scripts/create_newcase \
            --case ${CASE_NAME} \
            --output-root ${CASE_ROOT} \
            --script-root ${CASE_SCRIPTS_DIR} \
            --handle-preexisting-dirs u \
            --compset ${COMPSET} \
            --res ${RESOLUTION} \
            --machine ${MACHINE} \
            --project ${PROJECT} \
            --walltime ${WALLTIME} \
            --pecount ${PELAYOUT}
    else
        ${CODE_ROOT}/cime/scripts/create_newcase \
            --case ${CASE_NAME} \
            --case-group ${CASE_GROUP} \
            --output-root ${CASE_ROOT} \
            --script-root ${CASE_SCRIPTS_DIR} \
            --handle-preexisting-dirs u \
            --compset ${COMPSET} \
            --res ${RESOLUTION} \
            --machine ${MACHINE} \
            --project ${PROJECT} \
            --walltime ${WALLTIME} \
            --pecount ${PELAYOUT}
    fi

    if [ $? != 0 ]; then
      echo $'\nNote: if create_newcase failed because sub-directory already exists:'
      echo $'  * delete old case_script sub-directory'
      echo $'  * or set do_newcase=false\n'
      exit 35
    fi

}

#-----------------------------------------------------
case_setup() {

    if [ "${do_case_setup,,}" != "true" ]; then
        echo $'\n----- Skipping case_setup -----\n'
        return
    fi

    echo $'\n----- Starting case_setup -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Setup some CIME directories
    ./xmlchange EXEROOT=${CASE_BUILD_DIR}
    ./xmlchange RUNDIR=${CASE_RUN_DIR}

    # Short term archiving
    ./xmlchange DOUT_S=${DO_SHORT_TERM_ARCHIVING^^}
    ./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}

    # QT turn off cosp for testing
    ## Build with COSP, except for a data atmosphere (datm)
    #if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then 
    #  echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    #else
    #  echo $'\nConfiguring E3SM to use the COSP simulator\n'
    #  ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    #fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # QT changing chemistry mechanism
    #local usr_mech_infile="${CODE_ROOT}/components/eam/chem_proc/inputs/pp_chemUCI_linozv3_mam4_resus_mom_soag_tag.in"
    #echo '[QT] Changing chemistry to :'${usr_mech_infile}
    #./xmlchange --id CAM_CONFIG_OPTS --append --val='-usr_mech_infile '${usr_mech_infile}

    # Custom user_nl
    user_nl

    # Finally, run CIME case.setup
    ./case.setup --reset

    popd
}

#-----------------------------------------------------
case_build() {

    pushd ${CASE_SCRIPTS_DIR}

    # do_case_build = false
    if [ "${do_case_build,,}" != "true" ]; then

        echo $'\n----- case_build -----\n'

        if [ "${OLD_EXECUTABLE}" == "" ]; then
            # Ues previously built executable, make sure it exists
            if [ -x ${CASE_BUILD_DIR}/e3sm.exe ]; then
                echo 'Skipping build because $do_case_build = '${do_case_build}
            else
                echo 'ERROR: $do_case_build = '${do_case_build}' but no executable exists for this case.'
                exit 297
            fi
        else
            # If absolute pathname exists and is executable, reuse pre-exiting executable
            if [ -x ${OLD_EXECUTABLE} ]; then
                echo 'Using $OLD_EXECUTABLE = '${OLD_EXECUTABLE}
                cp -fp ${OLD_EXECUTABLE} ${CASE_BUILD_DIR}/
            else
                echo 'ERROR: $OLD_EXECUTABLE = '$OLD_EXECUTABLE' does not exist or is not an executable file.'
                exit 297
            fi
        fi
        echo 'WARNING: Setting BUILD_COMPLETE = TRUE.  This is a little risky, but trusting the user.'
        ./xmlchange BUILD_COMPLETE=TRUE

    # do_case_build = true
    else

        echo $'\n----- Starting case_build -----\n'

        # Turn on debug compilation option if requested
        if [ "${DEBUG_COMPILE^^}" == "TRUE" ]; then
            ./xmlchange DEBUG=${DEBUG_COMPILE^^}
        fi

        # Run CIME case.build
        ./case.build

    fi

    # Some user_nl settings won't be updated to *_in files under the run directory
    # Call preview_namelists to make sure *_in and user_nl files are consistent.
    echo $'\n----- Preview namelists -----\n'
    ./preview_namelists

    popd
}

#-----------------------------------------------------
runtime_options() {

    echo $'\n----- Starting runtime_options -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Set simulation start date
    ./xmlchange RUN_STARTDATE=${START_DATE}

    # Segment length
    ./xmlchange STOP_OPTION=${STOP_OPTION,,},STOP_N=${STOP_N}

    # Restart frequency
    ./xmlchange REST_OPTION=${REST_OPTION,,},REST_N=${REST_N}

    # Coupler history
    ./xmlchange HIST_OPTION=${HIST_OPTION,,},HIST_N=${HIST_N}

    # Coupler budgets (always on)
    ./xmlchange BUDGETS=TRUE

    # Set resubmissions
    if (( RESUBMIT > 0 )); then
        ./xmlchange RESUBMIT=${RESUBMIT}
    fi

    # Run type
    # Start from default of user-specified initial conditions
    if [ "${MODEL_START_TYPE,,}" == "initial" ]; then
        ./xmlchange RUN_TYPE="startup"
        ./xmlchange CONTINUE_RUN="FALSE"

    # Continue existing run
    elif [ "${MODEL_START_TYPE,,}" == "continue" ]; then
        ./xmlchange CONTINUE_RUN="TRUE"

    elif [ "${MODEL_START_TYPE,,}" == "branch" ] || [ "${MODEL_START_TYPE,,}" == "hybrid" ]; then
        ./xmlchange RUN_TYPE=${MODEL_START_TYPE,,}
        ./xmlchange GET_REFCASE=${GET_REFCASE}
        ./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${RUN_REFDATE}
        echo 'Warning: $MODEL_START_TYPE = '${MODEL_START_TYPE} 
        echo '$RUN_REFDIR = '${RUN_REFDIR}
        echo '$RUN_REFCASE = '${RUN_REFCASE}
        echo '$RUN_REFDATE = '${START_DATE}
    else
        echo 'ERROR: $MODEL_START_TYPE = '${MODEL_START_TYPE}' is unrecognized. Exiting.'
        exit 380
    fi

    # Patch mpas streams files
    patch_mpas_streams

    popd
}

#-----------------------------------------------------
case_submit() {

    if [ "${do_case_submit,,}" != "true" ]; then
        echo $'\n----- Skipping case_submit -----\n'
        return
    fi

    echo $'\n----- Starting case_submit -----\n'
    pushd ${CASE_SCRIPTS_DIR}
    
    # Run CIME case.submit
    ./case.submit

    popd
}

#-----------------------------------------------------
copy_script() {

    echo $'\n----- Saving run script for provenance -----\n'

    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=`basename $0`
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp ${this_script_name} ${script_provenance_dir}/${script_provenance_name}

}

#-----------------------------------------------------
# Silent versions of popd and pushd
pushd() {
    command pushd "$@" > /dev/null
}
popd() {
    command popd "$@" > /dev/null
}

# Now, actually run the script
#-----------------------------------------------------
main

