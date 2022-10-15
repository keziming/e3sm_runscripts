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
readonly MACHINE=chrysalis
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="F20TR_chemUCI-Linozv3"
readonly RESOLUTION="ne30pg2_EC30to60E2r2"
readonly CASE_NAME="M4.UCI.M5-UCI-MOSAIC-MZT.NOx.t11.5days"
#readonly CASE_GROUP="v2.LR.chemUCI"

# Code and compilation
readonly CHECKOUT="chemUCI-MOSAIC-MAM5-08162022"
#readonly BRANCH="master"   #420e251265928a4122a5eb5d4eab4ae8110f84f2 05/172022  
readonly BRANCH="keziming/atm/chemUCI-MOSAIC-MAM5"     
#readonly CHERRY=( "7e4d1c9fec40ce1cf2c272d671f5d9111fa4dea7" "a5b1d42d7cd24924d0dbda95e24ad8d4556d93f1" ) # PR4349
readonly DEBUG_COMPILE=false

# Run options
readonly MODEL_START_TYPE="hybrid"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="2000-01-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=TRUE
readonly RUN_REFDIR="/lcrc/group/e3sm/ac.qtang/E3SM_simulations/20220518.v2.LR.bi-grid.amip.chemUCI_Linozv3/archive/rest/2000-01-01-00000/"
readonly RUN_REFCASE="20220518.v2.LR.bi-grid.amip.chemUCI_Linozv3"
readonly RUN_REFDATE="2000-01-01"   # same as MODEL_START_DATE for 'branch', can be different for 'hybrid'

# Set paths
readonly CODE_ROOT="${HOME}/E3SM_models/${CHECKOUT}"
#readonly CODE_ROOT="/qfs/people/tang338/E3SM_code/${CHECKOUT}"
readonly CASE_ROOT="/lcrc/group/e3sm/${USER}/E3SM_simulations/${CASE_NAME}"

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
  readonly WALLTIME="15:00:00"
  readonly STOP_OPTION="ndays"
  readonly STOP_N="1"
  readonly REST_OPTION="ndays"
  readonly REST_N="1"
  readonly RESUBMIT="0"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler histfalse 
readonly HIST_OPTION="nyears"
readonly HIST_N="5"

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


nhtfrq = 1,1,1,1,1,1,1
mfilt  = 48,48,48,48,48,48,48

 avgflag_pertape = 'A','I','I','I','I','I','I'

 fincl1 = 'PS','E90','N2OLNZ','NOYLNZ','H2OLNZ','CH4LNZ','MASS','AREA','TOZ','TROPC_P','TROPC_T','TROPC_Z','TROPS_P','TROPS_T','TROPS_Z','TROPT_P','TROPT_T','TROPT_Z','TROPW_P','TROPW_T','TROPW_Z','TROPH_P','TROPH_T','TROPH_Z','TROPE_P','TROPE_T','TROPE_Z',"O3","OH","HO2","H2O2","NO","NO2","NO3","N2O5","HNO3","HO2NO2","CO","CH2O","CH3O2","CH3OOH","DMS","SO2","ISOP","H2SO4","SOAG","so4_a1","pom_a1","soa_a1","bc_a1 ","dst_a1","ncl_a1","mom_a1","num_a1","so4_a2","soa_a2","ncl_a2","mom_a2","num_a2","dst_a3","ncl_a3","so4_a3","bc_a3","pom_a3","soa_a3","mom_a3","num_a3","pom_a4","bc_a4","mom_a4","num_a4","M_dens","H2O_vmr","CH4","NO_Lightning","NO_Aircraft","CO_Aircraft","CH4_vmr","prsd_ch4","C2H5OOH","CH3CHO",'LNO_COL_PROD','LNO_PROD','PAN','DV_O3','PS','PSDRY','lch4','r_lch4','M_dens','lco_h','r_lco_h','uci1','r_uci1'

  fincl2 = 'PS','T','E90','N2OLNZ','NOYLNZ','H2OLNZ','CH4LNZ','MASS','AREA','TOZ','TROPC_P','TROPC_T','TROPC_Z','TROPS_P','TROPS_T','TROPS_Z','TROPT_P','TROPT_T','TROPT_Z','TROPW_P','TROPW_T','TROPW_Z','TROPH_P','TROPH_T','TROPH_Z','TROPE_P','TROPE_T','TROPE_Z',"O3","OH","HO2","H2O2","NO","NO2","NO3","N2O5","HNO3","HO2NO2","CO","CH2O","CH3O2","CH3OOH","DMS","SO2","ISOP","H2SO4","SOAG","so4_a1","pom_a1","soa_a1","bc_a1 ","dst_a1","ncl_a1","mom_a1","num_a1","so4_a2","soa_a2","ncl_a2","mom_a2","num_a2","dst_a3","ncl_a3","so4_a3","bc_a3","pom_a3","soa_a3","mom_a3","num_a3","pom_a4","bc_a4","mom_a4","num_a4","M_dens","H2O_vmr","CH4","NO_Lightning","NO_Aircraft","CO_Aircraft","CH4_vmr","prsd_ch4","C2H5OOH","CH3CHO",'LNO_COL_PROD','LNO_PROD','PAN','DV_O3','PS','PSDRY','lch4','r_lch4','M_dens','lco_h','r_lco_h','uci1','r_uci1'

 
  fincl3 = 'PS','T','Z3','M_dens','M_vmr','N2_dens','N2_vmr','O2_dens','O2_vmr','H2O_dens','H2O_vmr','H2_dens','H2_vmr','CH4_dens','CH4_vmr',
       'CO',
      'C2H6',
      'C3H8',
      'CH3COCH3',
      'E90',
      'N2OLNZ',
      'NOYLNZ',
      'CH4LNZ',
      'H2OLNZ',
      'DMS',
      'SO2',
      'H2SO4',
      'SOAG',
      'so4_a1',
      'so4_a2',
      'so4_a3',
      'pom_a1',
      'pom_a3',
      'pom_a4',
      'soa_a1',
      'soa_a2',
      'soa_a3',
      'bc_a1',
      'bc_a3',
      'bc_a4',
      'dst_a1',
      'dst_a3',
      'ncl_a1',
      'ncl_a2',
      'ncl_a3',
      'mom_a1',
      'mom_a2',
      'mom_a3',
      'mom_a4',
      'num_a1',
      'num_a2',
      'num_a3',
      'num_a4',
      'O3',
      'OH',
      'HO2',
      'H2O2',
      'CH2O',
      'CH3O2',
      'CH3OOH',
      'NO',
      'NO2',
      'NO3',
            'N2O5',
            'HNO3',
      'HO2NO2',
      'PAN',
      'C2H5O2',
      'C2H5OOH',
      'CH3CHO',
      'CH3CO3',
      'C2H4',
      'ROHO2',
      'ISOP',
      'ISOPO2',
      'MVKMACR',
      'MVKO2'


fincl4 = 'PS','H2O_vmr','T',
         'uci1', 'uci2', 'uci3', 'lco_h','lco_ho2',
         'lh2_ho2','lch4','lc2h6','lc3h8','lc2h4_oh',
         'lc2h4_o3', 'lisop_o3','lisop_oh','lch2o','lo3_oh',
         'po3_oh','lo3_ho2','lho2_oh','uci4','uci5',
         'ph2o2','lh2o2','lo3_no','lno_ho2','lo3_no2',
         'lno3_oh','lno3_no','lhno4','lhno3','uci6',
         'lno2_oh','HO2NO2f','N2O5f','PANf','uci7',
         'uci8', 'uci9','lch3o2_ho2','lch3o2_no','lch3o2',
         'lch3ooh', 'lc2h5o2_no','lc2h5o2','lc2h5o2_ch3','lc2h5o2_ho2',
         'lc2h5ooh_a', 'lc2h5ooh_b','lch3cho_oh','lch3cho_no3','lch3co3_no',
         'lch3co3_ch3', 'lch3co3','lch3coch3_a','lch3coch3_b','lroho2_no',
         'lroho2_ho2', 'lroho2_ch3o2','lisopo2_no','lisopo2_ho2','lisopo2_ch3',
         'lmvkmacr_o3', 'lmvkmacr_oh','lmvko2_no','lmvko2_ho2','usr_e90',
         'ldms_oh','usr_DMS_OH','usr_SO2_OH','ldms_no3'


fincl5 = 'PS','H2O_vmr','T',
         'r_uci1', 'r_uci2', 'r_uci3', 'r_lco_h','r_lco_ho2',
         'r_lh2_ho2','r_lch4','r_lc2h6','r_lc3h8','r_lc2h4_oh',
         'r_lc2h4_o3', 'r_lisop_o3','r_lisop_oh','r_lch2o','r_lo3_oh',
         'r_po3_oh','r_lo3_ho2','r_lho2_oh','r_uci4','r_uci5',
         'r_ph2o2','r_lh2o2','r_lo3_no','r_lno_ho2','r_lo3_no2',
         'r_lno3_oh','r_lno3_no','r_lhno4','r_lhno3','r_uci6',
         'r_lno2_oh','r_HO2NO2f','r_N2O5f','r_PANf','r_uci7',
         'r_uci8', 'r_uci9','r_lch3o2_ho2','r_lch3o2_no','r_lch3o2',
         'r_lch3ooh', 'r_lc2h5o2_no','r_lc2h5o2','r_lc2h5o2_ch3','r_lc2h5o2_ho2',
         'r_lc2h5ooh_a', 'r_lc2h5ooh_b','r_lch3cho_oh','r_lch3cho_no3','r_lch3co3_no',
         'r_lch3co3_ch3', 'r_lch3co3','r_lch3coch3_a','r_lch3coch3_b','r_lroho2_no',
         'r_lroho2_ho2', 'r_lroho2_ch3o2','r_lisopo2_no','r_lisopo2_ho2','r_lisopo2_ch3',
         'r_lmvkmacr_o3', 'r_lmvkmacr_oh','r_lmvko2_no','r_lmvko2_ho2','r_e90',
         'r_ldms_oh','r_DMS_OH','r_SO2_OH','r_ldms_no3'
         


fincl6 = 'jo1dU','jo2_b', 'jh2o2', 'jch2o_a', 'jch2o_b',
         'jch3ooh', 'jc2h5ooh', 'jno2','jno3_a','jno3_b',
         'jn2o5_a','jn2o5_b','jhno3','jho2no2_a','jho2no2_b',
         'jch3cho','jpan','jacet','jmvk'
fincl7 = 'r_jo1dU', 'r_jo2_b', 'r_jh2o2', 'r_jch2o_a', 'r_jch2o_b',
         'r_jch3ooh', 'r_jc2h5ooh', 'r_jno2', 'r_jno3_a', 'r_jno3_b',
         'r_jn2o5_a','r_jn2o5_b','r_jhno3','r_jho2no2_a','r_jho2no2_b',
         'r_jch3cho','r_jpan','r_jacet','r_jmvk'



 tropopause_e90_thrd            = 80.0e-9

 !history_gaschmbudget = .true.
 history_gaschmbudget_2D = .true.
 history_gaschmbudget_2D_levels = .true.
 history_UCIgaschmbudget_2D = .true.
 history_UCIgaschmbudget_2D_levels = .true.
 gaschmbudget_2D_L1_s =  1
 gaschmbudget_2D_L1_e = 26
 gaschmbudget_2D_L2_s = 27
 gaschmbudget_2D_L2_e = 38
 gaschmbudget_2D_L3_s = 39
 gaschmbudget_2D_L3_e = 58
 gaschmbudget_2D_L4_s = 59
 gaschmbudget_2D_L4_e = 72

 linoz_psc_t = 198.0
 rad_climate            = 'A:H2OLNZ:H2O', 'N:O2:O2', 'N:CO2:CO2',
         'A:O3:O3', 'A:N2OLNZ:N2O', 'A:CH4LNZ:CH4',
         'N:CFC11:CFC11', 'N:CFC12:CFC12',
         'M:mam4_mode1:/lcrc/group/e3sm/data/inputdata/atm/cam/physprops/mam4_mode1_rrtmg_aeronetdust_c141106.nc',
         'M:mam4_mode2:/lcrc/group/e3sm/data/inputdata/atm/cam/physprops/mam4_mode2_rrtmg_c130628.nc',
         'M:mam4_mode3:/lcrc/group/e3sm/data/inputdata/atm/cam/physprops/mam4_mode3_rrtmg_aeronetdust_c141106.nc',
         'M:mam4_mode4:/lcrc/group/e3sm/data/inputdata/atm/cam/physprops/mam4_mode4_rrtmg_c130628.nc'

 sad_file               = '/lcrc/group/e3sm/data/inputdata/atm/waccm/sulf/SAD_SULF_1849-2100_1.9x2.5_c090817.nc'


EOF

cat << EOF >> user_nl_elm
 check_finidat_year_consistency = .false.
 check_dynpft_consistency = .false.
 fsurdat = "/lcrc/group/e3sm/data/inputdata/lnd/clm2/surfdata_map/surfdata_ne30pg2_simyr1850_c210402.nc"


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
    if [ "${run}" != "production" ]; then
       local CASE_ROOT_1="/lcrc/group/e3sm/${USER}/E3SM_simulations/${CASE_NAME}/tests/S_1x5_ndays/case_scripts/"      
    else
       local CASE_ROOT_1="$CASE_ROOT/case_scripts/"	    
    fi
    echo $CASE_ROOT_1
    local usr_mech_infile="${CODE_ROOT}/components/eam/chem_proc/inputs/pp_chemUCI_linozv3_mam4_resus_mom_soag_tag_n2o5_to_HNO3_PAN_0914.in" 
    ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp -chem superfast_mam4_resus_mom_soag -rain_evap_to_coarse_aero -nlev 72 -usr_mech_infile '${usr_mech_infile}
    #./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp '
    # Custom user_nl
    user_nl
    ./xmlchange --id SSTICE_DATA_FILENAME --val='$DIN_LOC_ROOT/ocn/docn7/SSTDATA/sst_ice_CMIP6_DECK_E3SM_1x1_c20180213.nc'

    #cp  /home/ac.zke/E3SM_codes/uci_nox_test/turn_off_NOYLNZ/lin_strat_chem.F90  ${CASE_SCRIPTS_DIR}/SourceMods/src.eam/
    cp /home/ac.zke/E3SM_codes/uci_nox_mo_gas_change1/mo_gas_phase_chemdr.F90 ${CASE_SCRIPTS_DIR}/SourceMods/src.eam/
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

