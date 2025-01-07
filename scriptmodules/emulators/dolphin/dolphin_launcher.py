#!/usr/bin/env python3
import argparse
import configparser
import pathlib
import shlex
import shutil
import subprocess
import sys
import os

import sdl2

# Disable HIDAPI to ensure compatibility with EmulationStation
os.environ["SDL_JOYSTICK_HIDAPI"] = "0"

configparser.ConfigParser.optionxform = str
dolphin_config = pathlib.Path("/opt/retropie/configs/gc/Config")
# dolphin_config = pathlib.Path("/home/golden/.var/app/org.DolphinEmu.dolphin-emu/config/dolphin-emu")
profile_dirs = {
    "gc": dolphin_config / "Profiles/GCPad",
    "wii": dolphin_config / "Profiles/Wiimote",
}
section_names = {
    "gc": "GCPad",
    "wii": "Wiimote",
}
dolphin_keybinds = {
    "gc": dolphin_config / "GCPadNew.ini",
    "wii": dolphin_config / "WiimoteNew.ini",
}
dolphin_temp_keybinds = {
    "gc": pathlib.Path("/tmp/GCPadNew.ini"),
    "wii": pathlib.Path("/tmp/WiimoteNew.ini"),
}
dolphin_hotkeys = dolphin_config / "Hotkeys.ini"
dolphin_settings = dolphin_config / "Dolphin.ini"
dolphin_emu = pathlib.Path("/opt/retropie/emulators/dolphin/bin/dolphin-emu")
dolphin_tool = pathlib.Path("/opt/retropie/emulators/dolphin/bin/dolphin-tool")


def get_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("console", help="Console to use")
    parser.add_argument("game", help="Game to start")

    return parser.parse_args()

def get_gamepad_config(gamepad_name, profile_type):
    sanitise_table = dict.fromkeys(map(ord, ':><?"/\\|*'), None)
    filename = f'{gamepad_name.translate(sanitise_table)}.ini'

    profile_dir = profile_dirs[profile_type]
    profile_file = profile_dir / filename
    print(profile_file)
    if not profile_file.exists():
        print(f"Profile {filename} not found for {profile_type}")
        return None
    config = configparser.ConfigParser()
    config.read(profile_file)
    return config['Profile']

def find_game_controllers(profile_type) -> list[dict]:
    print("Scanning for game controllers...")
    gamepads: list[dict] = []
    sdl_cache: list[str] = []
    # with open("/proc/bus/input/devices") as f:
        # # evdev_name = ""
        # sdl_name = ""
        # js_index = ""
        # for line in f:
            # line = line.strip()
            # # print(line)
            # if line.startswith("I:"):
                # evdev_name = ""
                # sdl_name = ""
                # js_index = ""
            # elif line.startswith("N:"):
                # evdev_name = line.split("Name=")[1].strip()[1:-1]
            # elif line.startswith("H:") and "js" in line:
                # js_index = line.split("js")[1].strip()
                # sdl_name = sdl2.SDL_GameControllerNameForIndex(int(js_index)).decode("utf-8")
                # c = 0
                # while True:
                    # dolphin_name = f'SDL/{c}/{sdl_name}'
                    # if dolphin_name not in sdl_cache:
                        # sdl_cache.append(dolphin_name)
                        # config = get_gamepad_config(evdev_name, profile_type)
                        # if config is not None:
                            # gamepads.append((evdev_name, dolphin_name, js_index, config))
                        # break
                    # c += 1
    for i in range(sdl2.SDL_NumJoysticks()):
        gamepad_name = sdl2.SDL_GameControllerNameForIndex(i).decode("utf-8")
        js_name = sdl2.SDL_JoystickNameForIndex(i).decode("utf-8")
        c = 0
        while True:
            dolphin_name = f'SDL/{c}/{gamepad_name}'
            if dolphin_name not in sdl_cache:
                sdl_cache.append(dolphin_name)
                config = get_gamepad_config(js_name, profile_type)
                if config is not None:
                    gamepads.append({
                        'name': dolphin_name,
                        'config': config})
                break
            c += 1
    print(gamepads)
    return gamepads

def create_new_config(gamepads, console):
    new_config = configparser.ConfigParser()
    for i, gamepad in enumerate(gamepads, start=1):
        controller_config = gamepad['config']
        controller_config['Device'] = gamepad['name']
        controller_config['Source'] = '1'
        new_config[f'{section_names[console]}{i}'] = controller_config
    #with open("new.ini", "w") as f:
    #    new_config.write(f)
    return new_config

def create_new_hotkeys(gamepad, console):
    new_config = configparser.ConfigParser()
    home_button = 'Buttons/Home' if console == 'wii' else 'Hotkey'
    a_key = gamepad['config']['Buttons/A'] # on the wii is flipped
    b_key = gamepad['config']['Buttons/B'] # same
    home_key = gamepad['config'][home_button]
    new_config.add_section('Hotkeys')
    new_config['Hotkeys']['Device'] = gamepad['name']
    new_config['Hotkeys']['General/Stop'] = f'{home_key}&{a_key}&{b_key}'
    return new_config

def create_empty_config(console):
    new_config = configparser.ConfigParser()
    for i in range(1, 5):
        new_config[f'{section_names[console]}{i}'] = {"Source": "0"}
    return new_config

def start_game(game,
               selected_console,
               gamepad_config,
               hotkey_config):
    old_stopconfirm = ""
    try:
        for console in dolphin_keybinds:
            if dolphin_keybinds[console].exists():
                shutil.move(dolphin_keybinds[console], dolphin_temp_keybinds[console])
            with open(dolphin_keybinds[console], "w") as f:
                if console == selected_console:
                    print(f"Writing new keybinds at {dolphin_keybinds[selected_console]}")
                    gamepad_config.write(f)
                else:
                    print(f"Writing empty keybinds at {dolphin_keybinds[console]}")
                    create_empty_config(console).write(f)
        if dolphin_hotkeys.exists():
            shutil.move(dolphin_hotkeys, pathlib.Path("/tmp/Hotkeys.ini"))
        dolphin_config = configparser.ConfigParser()
        dolphin_config.read(dolphin_settings)
        if "ConfirmStop" in dolphin_config["Interface"]:
            old_stopconfirm = dolphin_config["Interface"]["ConfirmStop"]
        dolphin_config["Interface"]["ConfirmStop"] = "False"
        with open(dolphin_settings, "w") as f:
            dolphin_config.write(f)
        with open(dolphin_hotkeys, "w") as f:
            print(f"Writing new hotkeys at {dolphin_hotkeys}")
            hotkey_config.write(f)
        launch_cmd = f'{dolphin_emu} -b -e "{game}"'
        proc = subprocess.Popen(shlex.split(launch_cmd))
        proc.wait()
    finally:
        print("Restoring original keybinds")
        for console in dolphin_keybinds:
            if dolphin_temp_keybinds[console].exists():
                shutil.move(dolphin_temp_keybinds[console], dolphin_keybinds[console])
            else:
                dolphin_keybinds[console].unlink()
        print("Restoring original stop confirm")
        dolphin_config = configparser.ConfigParser()
        dolphin_config.read(dolphin_settings)
        dolphin_config["Interface"]["ConfirmStop"] = old_stopconfirm
        with open(dolphin_settings, "w") as f:
            dolphin_config.write(f)
        print("Restoring original hotkeys")
        if pathlib.Path("/tmp/Hotkeys.ini").exists():
            shutil.move(pathlib.Path("/tmp/Hotkeys.ini"), dolphin_hotkeys)
        else:
            dolphin_hotkeys.unlink()

def main(rom, selected_console):
    sdl2.SDL_Init(sdl2.SDL_INIT_JOYSTICK | sdl2.SDL_INIT_GAMECONTROLLER)
    gamepads = find_game_controllers(selected_console)
    new_config = create_new_config(gamepads, selected_console)
    new_hotkey_config = create_new_hotkeys(gamepads[0], selected_console)
    start_game(rom, selected_console, new_config, new_hotkey_config)

if __name__ == "__main__":
    args = get_args()
    print(args)
    main(args.game, args.console)
