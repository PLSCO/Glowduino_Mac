#!/bin/bash
#!/bin/sh

echo redrum82 | sudo -S Command

BASEDIR=$(dirname $0)

if [ -n "$1" ]; then
    BINFILE="$1"
else
    BINFILE="/tmp/glowdeck_firmware.bin"
fi

i=0
while read line
do
    array[ $i ]="$line"        
    (( i++ ))
done < <(sudo ls /dev/cu.usbmodem*)

echo " OK"
#echo ${array[1]}
USBSERIAL=${array[1]}
 
echo "Glowdeck V3 Firmware Uploader"

# Glowdeck to bootloader mode
if [ -n "$USBSERIAL" ]; then
    echo "Putting Glowdeck in DFU mode..."
    stty -f "$USBSERIAL" speed 9600 cs8 -cstopb -parenb -echo
    sleep 2
    echo -e "GFU^\r" > "$USBSERIAL"
    sleep 2
fi

if [ -d /Volumes/Glowdeck ]; then
    sudo rm -rf /Volumes/Glowdeck
fi

fstabout=`sudo cat /etc/fstab |grep "GLOWDECK_V[0-9]"`

if [ -n "$fstabout" ]; then
    echo "Scanning for Glowdeck MSD..."
else
    echo "* Glowdeck One-Time MSD Configuration Setup *"
    echo "Please follow these steps to enable direct firmware uploads (via USB) on macOS."
    echo "WARNING: Failure to follow these steps exactly as shown can lead to system instability. Proceed carefully."
    echo "1. From a Terminal prompt, type (without the quotations): \"sudo vifs\""
    echo "2. Press Enter - type your Mac password if prompted - and a file editor will open."
    echo "3. Press the \"i\" key to activate insert text mode."
    echo "4. Use the keyboard arrows to navigate the cursor to the bottom of the file/screen."
    echo "5. Add the following 2 lines, exactly as they appear below, to the bottom/end of the file:"
    echo "LABEL=GLOWDECK_V1 none msdos rw,noauto 0,0"
    echo "LABEL=GLOWDECK_V2 none msdos rw,noauto 0,0"
    echo "LABEL=GLOWDECK_V3 none msdos rw,noauto 0,0"
    echo "6. Press the \"Esc\" key."
    echo "7. Type the following characters (without the quotations) \":wq\""
    echo "8. Press Enter. The one-time setup procedure is now complete."
    echo "9. If connected, disconnect and then reconnect Glowdeck from your computer's USB port."
    echo "10. Upload your firmware (you will never need to follow these steps again)."
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.fseventsd.plist
    exit 1;
fi

sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.fseventsd.plist
sudo mkdir /Volumes/Glowdeck

diskname=
disknames=`diskutil list GLOWDECK_V1 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`

until [ -n "$disknames" ]
do
    disknames=`diskutil list GLOWDECK_V1 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`

    if [ -n "$disknames" ]; then
        diskname="/dev/"
        diskname+=`diskutil list GLOWDECK_V1 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`
        echo "Found Glowdeck V1..."
        break
    else
        disknames=`diskutil list GLOWDECK_V2 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`
        if [ -n "$disknames" ]; then
            diskname="/dev/"
            diskname+=`diskutil list GLOWDECK_V2 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`
            echo "Found Glowdeck V2..."
            break
        else
            disknames=`diskutil list GLOWDECK_V3 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`
            if [ -n "$disknames" ]; then
                diskname="/dev/"
                diskname+=`diskutil list GLOWDECK_V3 | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'`
                echo "Found Glowdeck V3..."
                break
            fi
        fi
    fi

    sleep 1
done



# Mount MSD
echo "Mounting Glowdeck..."
sudo mount -t msdos $diskname /Volumes/Glowdeck
sleep 1

osascript <<EOF
set startTime to current date
tell application "System Events"
    repeat until exists application process "UserNotificationCenter"
        if (current date) - startTime is greater than 14 then
            error "Error: Glowdeck MSD not found and operation timed out."
            exit repeat
        end if
        delay 0.1
    end repeat
    tell application "UserNotificationCenter" to activate
    keystroke return
end tell
EOF

echo "Uploading firmware to Glowdeck..."
sudo $BASEDIR/mcopy $BINFILE /Volumes/Glowdeck/firmware.bin
#sudo $BASEDIR/teensy_reboot
sleep 5
echo "Finishing upload..."

sudo diskutil eject /Volumes/Glowdeck
sleep 3

sudo $BASEDIR/teensy_restart
sleep 2

sudo $BASEDIR/teensy_reboot
sleep 1

echo "Please leave Glowdeck attached while macOS is given time to clear the cache..."

sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.fseventsd.plist

sleep 2

CURR_PATH=`dirname "$0"`
CURR_PATH=`( cd "$CURR_PATH" && pwd )`

osascript <<EOT
tell application "System Events" to display dialog "Success, reset or power-cycle Glowdeck to load your new firmware" buttons {"OK"} default button {"OK"} with icon POSIX file ("$CURR_PATH/GlowdeckIcon.icns") with title "Glowdeck" giving up after 5
EOT

exit 0