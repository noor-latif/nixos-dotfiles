#!/usr/bin/env bash

startd=$(pgrep waybar)

if [ -n "$startd" ]; then
	pkill waybar
else
	waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css
fi
