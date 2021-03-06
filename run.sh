#!/bin/bash
set -e

MQTT_IP=xxx.xxx.xxx.xxx
MQTT_PORT=1883
MQTT_USER=user
MQTT_PASSWORD=pass
COMMAND_TOPIC=tv/living_room
STATE_TOPIC=tv/living_room/state
DEBUG_TOPIC=tv/living_room/debug

cec_on() {
  echo "on 0" | cec-client -s > /dev/null
}

cec_off() {
  echo "standby 0" | cec-client -s > /dev/null
}

cec_status() {
  while /bin/true; do
    STATUS=$(echo 'pow 0' | cec-client -s | grep 'power status:')
    OUTPUT=""

    mosquitto_pub -r -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "$DEBUG_TOPIC" -m "$STATUS" || true

    if [[ $STATUS == *"on"* ]]; then
      OUTPUT="On"
    fi

    if [[ $STATUS == *"standby"* ]]; then
      OUTPUT="Off"
    fi

    if [ $OUTPUT ]; then
      mosquitto_pub -r -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "$STATE_TOPIC" -m "$OUTPUT" || true
    fi

    sleep 5
  done
}

cec_status &

while read -r msg
do

  case $msg in
  On)
    cec_on &
    ;;
  Off)
    cec_off &
    ;;
  esac

done < <(mosquitto_sub -h "$MQTT_IP" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "$COMMAND_TOPIC" -q 1)
