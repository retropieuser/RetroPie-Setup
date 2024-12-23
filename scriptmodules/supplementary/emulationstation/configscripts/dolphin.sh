#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
declare -A _tmp_config_files=(
    [gc]="/tmp/gctempconfig.cfg"
    [wii]="/tmp/wiitempconfig.cfg"
)
declare -A _config_dirs=(
    [gc]="$configdir/gc/Config/Profiles/GCPad"
    [wii]="$configdir/gc/Config/Profiles/Wiimote"
)

_extension_string='Extension = $s=if(pulse(GUIDE,0.3)&pulse(A_BUTTON,0.1),if($s<2&$s>0,0,1),if(pulse(GUIDE,0.3)&pulse(B_BUTTON,0.1),if($s<3&$s>1,0,2),$s))'

function onstart_dolphin_joystick() {
    # write a temp file that will become the Controller Profile
    #
    for _tmp_filename in "${_tmp_config_files[@]}"; do
        if [[ -f "$_tmp_filename" ]]; then
            rm "$_tmp_filename"
        fi
        #iniConfig " = " "" "$_tmp_config_file"
        cat <<EOF > "$_tmp_filename"
[Profile]
EOF
    done

    #check if file exists
    if [[ ! -f "${_tmp_config_files[gc]}" ]]; then
        echo "Failed to create ${_tmp_config_files[gc]}"
    fi
    if [[ ! -f "${_tmp_config_files[wii]}" ]]; then
        echo "Failed to create ${_tmp_config_files[wii]}"
    fi
}


function map_dolphin_joystick() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local gc_keys
    local wii_keys
    local dir


    local is_guide
    local is_a
    local is_b
    case "$input_name" in
        up)
            gc_keys=("D-Pad/Up")
            wii_keys=("D-Pad/Up" "Classic/D-Pad/Up")
            dir=("N")
            ;;
        down)
            gc_keys=("D-Pad/Down")
            wii_keys=("D-Pad/Down" "Classic/D-Pad/Down")
            dir=("S")
            ;;
        left)
            gc_keys=("D-Pad/Left")
            wii_keys=("D-Pad/Left" "Classic/D-Pad/Left")
            dir=("W")
            ;;
        right)
            gc_keys=("D-Pad/Right")
            wii_keys=("D-Pad/Right" "Classic/D-Pad/Right")
            dir=("E")
            ;;
        b)
            gc_keys=("Buttons/B")
            wii_keys=("Buttons/B" "Classic/Buttons/A")
            is_b=true
            ;;
        y)
            gc_keys=("Buttons/Y")
            wii_keys=("Buttons/2" "Classic/Buttons/X")
            ;;
        a)
            gc_keys=("Buttons/A")
            wii_keys=("Buttons/A" "Classic/Buttons/B")
            is_a=true
            ;;
        x)
            gc_keys=("Buttons/X")
            wii_keys=("Buttons/1" "Classic/Buttons/Y")
            ;;
        leftbottom|leftshoulder)
            gc_keys=("Triggers/L")
            wii_keys=("Nunchuk/Buttons/C" "Classic/Buttons/ZL")
            ;;
        rightbottom|rightshoulder)
            gc_keys=("Triggers/R")
            wii_keys=("Shake/X" "Shake/Y" "Shake/Z" "Classic/Buttons/ZR")
            ;;
        righttop|righttrigger)
            gc_keys=("Buttons/Z")
            wii_keys=("Nunchuk/Shake/X" "Nunchuk/Shake/Y" "Nunchuk/Shake/Z" "Classic/Buttons/R-Analog")
            ;;
        lefttop|lefttrigger)
            wii_keys=("Nunchuk/Buttons/Z" "Classic/Buttons/L-Analog")
            ;;
        start)
            gc_keys=("Buttons/Start")
            wii_keys=("Buttons/+" "Classic/Buttons/+")
            ;;
        select)
            wii_keys=("Buttons/-" "Classic/Buttons/-")
            ;;
        leftanalogleft)
            gc_keys=("Main Stick/Left")
            wii_keys=("Nunchuk/Left" "Classic/Left Stick/Left")
            dir=("W")
            ;;
        leftanalogright)
            gc_keys=("Main Stick/Right")
            wii_keys=("Nunchuk/Right" "Classic/Left Stick/Right")
            dir=("E")
            ;;
        leftanalogup)
            gc_keys=("Main Stick/Up")
            wii_keys=("Nunchuk/Up" "Classic/Left Stick/Up")
            dir=("N")
            ;;
        leftanalogdown)
            gc_keys=("Main Stick/Down")
            wii_keys=("Nunchuk/Down" "Classic/Left Stick/Down")
            dir=("S")
            ;;
        rightanalogleft)
            gc_keys=("C-Stick/Left")
            wii_keys=("IR/Left" "Classic/Right Stick/Left")
            dir=("W")
            ;;
        rightanalogright)
            gc_keys=("C-Stick/Right")
            wii_keys=("IR/Right" "Classic/Right Stick/Right")
            dir=("E")
            ;;
        rightanalogup)
            gc_keys=("C-Stick/Up")
            wii_keys=("IR/Up" "Classic/Right Stick/Up")
            dir=("N")
            ;;
        rightanalogdown)
            gc_keys=("C-Stick/Down")
            wii_keys=("IR/Down" "Classic/Right Stick/Down")
            dir=("S")
            ;;
        hotkeyenable)
            gc_keys=("Hotkey")
            wii_keys=("Buttons/Home" "Classic/Buttons/Home")
            is_guide=true
            ;;
        *)
            return
            ;;
    esac

    local key
    local value

    iniConfig " = " "" "${_tmp_config_files[gc]}"
    for key in "${gc_keys[@]}"; do
        # read key value. Axis takes two key/axis values.
        value=$(translate_dolphin_value "$input_name" "$input_type" "$input_id" "$input_value" "$key")
        iniSet "$key" "$value"
    done
    iniConfig " = " "" "${_tmp_config_files[wii]}"
    for key in "${wii_keys[@]}"; do
        value=$(translate_dolphin_value "$input_name" "$input_type" "$input_id" "$input_value" "$key")
        iniSet "$key" "$value"
    done

    if [[ "$is_guide" == "true" ]]; then
        _extension_string="${_extension_string//GUIDE/$value}"
    elif [[ "$is_a" == "true" ]]; then
        _extension_string="${_extension_string//A_BUTTON/$value}"
    elif [[ "$is_b" == "true" ]]; then
        _extension_string="${_extension_string//B_BUTTON/$value}"
    fi
}

function translate_dolphin_value() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"
    local key="$5"
    iniGet "$key"
    case "$input_type" in
        axis)
            # key "X/Y Axis" needs different button naming
            if [[ "$key" == *Axis* ]]; then
                # if there is already a "-" axis add "+" axis value
                if [[ "$ini_value" == *\(* ]]; then
                    value="${ini_value}\`Axis ${input_id}+\`"
                # if there is already a "+" axis add "-" axis value
                elif [[ "$ini_value" == *\)* ]]; then
                    value="\`Axis ${input_id}-\`, ${ini_value}"
                # if there is no ini_value add "+" axis value
                elif [[ "$input_value" == "1" ]]; then
                    value="\`Axis ${input_id}+\`"
                else
                    value="\`Axis ${input_id}-\`"
                fi
            elif [[ "$input_value" == "1" ]]; then
                value="\`Axis ${input_id}+\` ${ini_value}"
            else
                value="\`Axis ${input_id}-\` ${ini_value}"
            fi
            ;;
        hat)
            if [[ "$key" == *Axis* ]]; then
                if [[ "$ini_value" == *\(* ]]; then
                    value="${ini_value}\`Hat ${input_id} ${dir}\`"
                elif [[ "$ini_value" == *\)* ]]; then
                    value="\`Hat ${input_id} ${dir}\`, ${ini_value}"
                elif [[ "$dir" == "N" || "$dir" == "W" ]]; then
                    value="\`Hat ${input_id} ${dir}\`"
                elif [[ "$dir" == "E" || "$dir" == "S" ]]; then
                    value="\`${dir}\`"
                fi
            else
                if [[ -n "$dir" ]]; then
                    value="\`Hat ${input_id} ${dir}\` ${ini_value}"
                fi
            fi
            ;;
        *)
            if [[ "$key" == *Axis* ]]; then
                if [[ "$ini_value" == *\(* ]]; then
                    value="${ini_value}\`Button ${input_id}\`"
                elif [[ "$ini_value" == *\)* ]]; then
                    value="\`Button ${input_id}\`, ${ini_value}"
                elif [[ "$dir" == "N" || "$dir" == "W" ]]; then
                    value="\`Button ${input_id}\`"
                elif [[ "$dir" == "E" || "$dir" == "S" ]]; then
                    value="\`${input_id}\`"
                fi
            else
                value="\`Button ${input_id}\` ${ini_value}"
            fi
            ;;
    esac
    echo "$value" | awk '{$1=$1};1'
}

function onend_dolphin_joystick() {
    local axis
    local dpad_axis

    # Check if any Main Stick entries exist
    if ! grep -q "Main Stick" ${_tmp_config_files[gc]}; then
        # List of D-Pad to Main Stick mappings
        declare -A axis_mapping=(
            ["D-Pad/Up"]="Main Stick/Up"
            ["D-Pad/Down"]="Main Stick/Down"
            ["D-Pad/Left"]="Main Stick/Left"
            ["D-Pad/Right"]="Main Stick/Right"
        )

        # Loop through the D-Pad mappings and rename them
        for dpad_axis in "${!axis_mapping[@]}"; do
            # Check if the D-Pad entry exists
            if grep -q "$dpad_axis" ${_tmp_config_files[gc]}; then
                # Get the value for the D-Pad entry
                iniGet "$dpad_axis"
                ini_value="$ini_value"

                # Set the corresponding Main Stick entry
                iniSet "${axis_mapping[$dpad_axis]}" "$ini_value"
                iniDel "$dpad_axis"  # Remove the D-Pad entry
            fi
        done
    fi

    # Map generic Stick cali
    cat <<EOF >> ${_tmp_config_files[gc]}
Main Stick/Calibration = 100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42
C-Stick/Calibration = 100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42
EOF

    cat <<EOF >> ${_tmp_config_files[wii]}
${_extension_string}
EOF

    # disable any auto configs for the same device to avoid duplicates
    local output_file
    for dir in "${_config_dirs[@]}"; do
        while read -r output_file; do
            mv "$output_file" "$output_file.bak"
        done < <(grep -Fl "\"$DEVICE_NAME\"" "$dir/"*.ini 2>/dev/null)
        # sanitise filename
        output_file="${DEVICE_NAME//[:><?\"\/\\|*]/}.ini"

        if [[ -f "$dir/$output_file" ]]; then
            mv "$dir/$output_file" "$dir/$output_file.bak"
        fi
    done

    mv "${_tmp_config_files[gc]}" "${_config_dirs[gc]}/$output_file"
    mv "${_tmp_config_files[wii]}" "${_config_dirs[wii]}/$output_file"

}
