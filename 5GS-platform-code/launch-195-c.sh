#!/usr/bin/env bash

# e.g.

# ./launch.sh 194_co 198_cu 195_du -noparser -s=ts

# Options:
# -nosync: passes "-s=0" as parameter to "log-parser-sim.py" to disable waiting for the "sim" command from the controller
# -nosshtime: do not run "sudo timedatectl set-time" (i.e. do not set remote computers date time)
# -noparser: do not run "log-parser-main.py"
# -s=SUFFIX: with this the configuration file will be "*-SUFFIX.yml" instead of "*.yml"

echo "==================================="
echo "Script name: ${0}"
echo "==================================="
echo

if [[ "$#" -lt 1 ]];
    then echo "Usage: launch all|[194_co, 198_cu, 193_du, 195_du] [-sim] [-nosync] [-nosshtime] [-noparser] [-s=SUFFIX]"
    exit 1
fi

# Default arguments values
HAS_ALL=0
HAS_194_CO=0
HAS_198_CU=0
HAS_195_DU=0
HAS_193_DU=0
HAS_SIM=0
HAS_SYNC=1
HAS_SSH_TIME=1
HAS_PARSER=1
SUFFIX=

# Assign passed argument values
for arg in "$@"; do
    case "$arg" in
        all) HAS_ALL=1 ;;
        194_co) HAS_194_CO=1 ;;
        198_cu) HAS_198_CU=1 ;;
        195_du) HAS_195_DU=1 ;;
        193_du) HAS_193_DU=1 ;;
        -sim) HAS_SIM=1 ;;
        -nosync) HAS_SYNC=0 ;;
        -nosshtime) HAS_SSH_TIME=0;;
        -noparser) HAS_PARSER=0;;
        -s=*) SUFFIX="${arg#-s=}" ;;
        *)
             echo "ERROR: Unknown argument: ${arg}";
             echo "Usage: launch all|[194_co, 198_cu, 193_du, 195_du] [-sim] [-nosync] [-nosshtime] [-noparser] [-s=SUFFIX]"
             exit 1
             ;;         
    esac
done

echo "OPTIONS:"
if (( HAS_ALL )); then
    echo "- all"
fi
if (( HAS_194_CO )); then
    echo "- 194 CORE"
fi
if (( HAS_198_CU )); then
    echo "- 198 CU"
fi
if (( HAS_195_DU )); then
    echo "- 195 DU"
fi
if (( HAS_193_DU )); then
    echo "- 193 DU"
fi
if (( HAS_SIM )); then
    echo "- sim"
fi
if (( !HAS_SIM )); then
    echo "- no sim (Default)"
fi
if (( HAS_SYNC )); then
    echo "- sync (Default)"
fi
if (( !HAS_SYNC )); then
    echo "- nosync"
fi
if (( HAS_SSH_TIME )); then
    echo "- sshtime (Default)"
fi
if (( !HAS_SSH_TIME )); then
    echo "- nosshtime"
fi
if (( HAS_PARSER )); then
    echo "- parser (Default)"
fi
if (( !HAS_PARSER )); then
    echo "- noparser"
fi

echo "- config file suffix: "$SUFFIX
echo

# NETWORK ELEMENTS:
# 194: Core Open5gs @ 192.168.0.194 (Deneb-4)
# 198: CU           @ 192.168.0.198 (Deneb-6)
# 195: DU B210      @ 192.168.0.195 (Asus)
# 193: DU B210      @ 192.168.0.193 (NUC)

D_194="Core Open5GS"
D_198="CU"
D_195="DU B210"
D_193="DU B210"

NAME_194="Deneb-4"
NAME_198="Deneb-6"
NAME_195="Asus"
NAME_193="NUC"

LAN_194="192.168.0.194"
LAN_198="192.168.0.198"
LAN_195="192.168.0.195"
LAN_193="192.168.0.193"

USER_194="epc"
USER_198="enb"
USER_195="ue"
USER_193="enb"

if [[ "$SUFFIX" == "ts" ]]; then
    echo "Using Tailscale IP addresses:"
    ADD_194="100.0.0.1"
    ADD_198="100.110.29.30"
    ADD_195="100.78.217.17"
    ADD_193="100.0.0.2"
else
    echo "Using LAN IP addresses:"
    ADD_194=$LAN_194
    ADD_198=$LAN_198
    ADD_195=$LAN_195
    ADD_193=$LAN_193
fi

echo "- ${LAN_194}: ${ADD_194}"
echo "- ${LAN_198}: ${ADD_198}" 
echo "- ${LAN_195}: ${ADD_195}" 
echo "- ${LAN_193}: ${ADD_193}" 
echo

if [[ -n "$SUFFIX" ]]; then
    SUFFIX="-$SUFFIX"
fi

if (( ! (HAS_ALL || HAS_194_CO || HAS_198_CU || HAS_195_DU || HAS_193_DU) ));
    then echo "Usage: launch all|[194_co, 198_cu, 193_du, 195_du] [-sim] [-nosync] [-nosshtime] [-noparser] [-s=SUFFIX]"
    exit 1
fi

if (( HAS_SYNC )); then
    SYNC=1
else
    SYNC=0
fi

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# SET DATE & TIME on remote machines
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

if (( HAS_SSH_TIME )); then
    echo "==================================="
    echo "Set date and time of remote machines (using current ${NAME_195} date and time)"
    echo "==================================="
    echo
    echo "- ${ADD_195} (${NAME_195})"
    timedatectl
    echo
fi

if (( ( HAS_198_CU || HAS_ALL ) && HAS_SSH_TIME )); then
    CD=$(date +"%Y-%m-%d %H:%M:%S")
    echo "- ${ADD_198} (${NAME_198})"
    echo "ssh ${USER_198}@${ADD_198} sudo timedatectl set-time '${CD}'"
    ssh "${USER_198}@${ADD_198}" "sudo timedatectl set-time '${CD}'"
    ssh "${USER_198}@${ADD_198}" "timedatectl"
    echo
fi

if (( ( HAS_194_CO || HAS_ALL ) && HAS_SSH_TIME )); then
    CD=$(date +"%Y-%m-%d %H:%M:%S")
    echo "- ${ADD_194} (${NAME_194})"
    echo "ssh ${USER_194}@${ADD_194} sudo timedatectl set-time '${CD}'"
    ssh "${USER_194}@${ADD_194}" "sudo timedatectl set-time '${CD}'"
    ssh "${USER_194}@${ADD_194}" "timedatectl"
    echo
fi

if (( ( HAS_193_DU || HAS_ALL ) && HAS_SSH_TIME )); then
    CD=$(date +"%Y-%m-%d %H:%M:%S")
    echo "- ${ADD_193} (${NAME_193})"
    echo "ssh ${USER_193}@${ADD_193} sudo timedatectl set-time '${CD}'"
    ssh "${USER_193}@${ADD_193}" "sudo timedatectl set-time '${CD}'"
    ssh "${USER_193}@${ADD_193}" "timedatectl"
    echo
fi

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# RUN srsRAN + Open5Gs + Parser
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# #######################################
# 194 CORE / Open5GS
# #######################################

if (( ( HAS_194_CO || HAS_ALL ) && !HAS_SIM )); then
    echo "==================================="
    echo "${D_194} @ ${ADD_194} (${NAME_194})"
    echo "==================================="
    echo
    echo "gnome-terminal --title=${ADD_194} (${NAME_194}) -- bash -c 'ssh -tt ${USER_194}@${ADD_194} 'cd /home/${USER_194}/code; ./jour-rt-lst-log.sh amf upf pcf ausf smf'; exec bash'"
    echo
    if (( HAS_PARSER )); then
        echo "gnome-terminal --title=${ADD_194} (${NAME_194}) -- bash -c 'ssh -tt ${USER_194}@${ADD_194} 'cd /home/${USER_194}/projects/srs-log; python3 log-parser-main.py -c=core -p=5000'; exec bash'"
        echo
    fi

    gnome-terminal --title="${ADD_194} (${NAME_194})" -- bash -c "ssh -tt ${USER_194}@${ADD_194} 'cd /home/${USER_194}/code; ./jour-rt-lst-log.sh amf upf pcf ausf smf'; exec bash"

    if (( HAS_PARSER )); then
        sleep 1
        gnome-terminal --title="${ADD_194} (${NAME_194})" -- bash -c "ssh -tt ${USER_194}@${ADD_194} 'cd /home/${USER_194}/projects/srs-log; python3 log-parser-main.py -c=core -p=5000'; exec bash"
    fi

fi

# #######################################
# 198 CU / srsRAN
# #######################################

if (( ( HAS_198_CU || HAS_ALL ) && !HAS_SIM )); then

    conf="gnb_split-8-cu-ho${SUFFIX}.yml"
  
    echo "==================================="
    echo "${D_198} @ ${ADD_198} (${NAME_198})"
    echo "==================================="
    echo
    echo "gnome-terminal --title=${ADD_198} (${NAME_198}) -- bash -c 'ssh -tt ${USER_198}@${ADD_198} 'sudo srscu -c /home/${USER_198}/config/srsran-5G/${conf}'; exec bash'"
    echo
    if (( HAS_PARSER )); then
        echo "gnome-terminal --title=${ADD_198} (${NAME_198}) -- bash -c 'ssh -tt ${USER_198}@${ADD_198} 'cd /home/${USER_198}/projects/srs-log; python3 log-parser-main.py -c=cu -p=5001'; exec bash'"
        echo
    fi

    ssh "${USER_198}@${ADD_198}" "echo ${conf} > /home/${USER_198}/config/srsran-5G/launch_srscu_conf.log"
    gnome-terminal --title="${ADD_198} (${NAME_198})" -- bash -c "ssh -tt ${USER_198}@${ADD_198} 'sudo srscu -c /home/${USER_198}/config/srsran-5G/${conf}'; exec bash"

    if (( HAS_PARSER )); then
        sleep 5
        gnome-terminal --title="${ADD_198} (${NAME_198})" -- bash -c "ssh -tt ${USER_198}@${ADD_198} 'cd /home/${USER_198}/projects/srs-log; python3 log-parser-main.py -c=cu -p=5001'; exec bash"
    fi
fi

# #######################################
# 195 DU / srsRAN
# #######################################

if (( ( HAS_195_DU || HAS_ALL ) && !HAS_SIM )); then

    conf="gnb_split-8-du-b210-ho${SUFFIX}.yml"

    echo "==================================="
    echo "${D_195} @ ${ADD_195} (${NAME_195})"
    echo "==================================="
    echo
    echo "gnome-terminal --title=${ADD_195} (${NAME_195}) -- bash -c 'sudo srsdu -c /home/${USER_195}/config/srsran-5G/${conf}; exec bash'"
    echo 
    if (( HAS_PARSER )); then
        echo "gnome-terminal --title=${ADD_195} (${NAME_195}) -- bash -c 'cd /home/${USER_195}/projects/srs-log; python3 log-parser-main.py -c=du -p=5000; exec bash'"
        echo
    fi

    echo "${conf}" > /home/${USER_195}/config/srsran-5G/launch_srsdu_conf.log
    gnome-terminal --title="${ADD_195} (${NAME_195})" -- bash -c "sudo srsdu -c /home/${USER_195}/config/srsran-5G/${conf}; exec bash"

    if (( HAS_PARSER )); then
         sleep 1
        gnome-terminal --title="${ADD_195} (${NAME_195})" -- bash -c "cd /home/${USER_195}/projects/srs-log; python3 log-parser-main.py -c=du -p=5000; exec bash"
    fi
fi

# #######################################
# 193 DU / srsRAN
# #######################################

if (( ( HAS_193_DU || HAS_ALL ) && !HAS_SIM )); then

    conf="gnb_split-8-du-b210-ho${SUFFIX}.yml"
    
    echo "==================================="
    echo "${D_193} @ ${ADD_193} (${NAME_193})"
    echo "==================================="
    echo
    echo "gnome-terminal --title=${ADD_193} (${NAME_193}) -- bash -c 'ssh -tt ${USER_193}@${ADD_193} 'sudo srsdu -c /home/${USER_193}/config/srsran-5G/${conf}'; exec bash'"
    echo
    if (( HAS_PARSER )); then
        echo "gnome-terminal --title=${ADD_193} (${NAME_193}) -- bash -c 'ssh -tt ${USER_193}@${ADD_193} 'cd /home/${USER_193}/projects/srs-log; python3 log-parser-main.py -c=du -p=5001'; exec bash'"
        echo
    fi

    ssh "${USER_193}@${ADD_193}" "echo ${conf} > /home/${USER_193}/config/srsran-5G/launch_srsdu_conf.log"
    gnome-terminal --title="${ADD_193} (${NAME_193})" -- bash -c "ssh -tt ${USER_193}@${ADD_193} 'sudo srsdu -c /home/${USER_193}/config/srsran-5G/${conf}'; exec bash"

    if (( HAS_PARSER )); then
        sleep 5
        gnome-terminal --title="${ADD_193} (${NAME_193})" -- bash -c "ssh -tt ${USER_193}@${ADD_193} 'cd /home/${USER_193}/projects/srs-log; python3 log-parser-main.py -c=du -p=5001'; exec bash"
    fi
fi

