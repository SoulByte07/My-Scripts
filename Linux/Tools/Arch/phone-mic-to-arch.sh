#!/bin/bash
# Phone-Mic: Stream Android mic to PipeWire virtual source
# pre-requisites: scrcpy with audio support, PipeWire, pactl
# Usage: ./phone-mic-to-arch.sh start|stop
# enable adb on phone, connect via USB, then run with "start" to begin streaming mic audio. Use "stop" to clean up.
# change the source in pavucontrol to "MobileMic" to use the phone mic in your apps

SINK_NAME="MobileMic"
SOURCE_NAME="MobileMic_Source"

function start_mic() {
    echo "--- Initializing Virtual Audio Nodes ---"
    pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description=$SINK_NAME
    pactl load-module module-remap-source master=$SINK_NAME.monitor source_name=$SOURCE_NAME source_properties=device.description=$SOURCE_NAME
    
    echo "--- Launching Scrcpy ---"
    # --no-video: we only want audio
    PULSE_SINK=$SINK_NAME scrcpy --no-video --no-window --audio-source=mic
}

function stop_mic() {
    echo "--- Cleaning up ---"
    pkill -f "scrcpy --no-video"
    pactl unload-module module-null-sink
    pactl unload-module module-remap-source
}

case "$1" in
    start) start_mic ;;
    stop)  stop_mic ;;
    *)     echo "Usage: $0 {start|stop}" ;;
esac
