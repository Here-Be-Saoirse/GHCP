#!/bin/bash
# GHCP - the Google Home Command Prompt
# interact with your google home over the network
# Copyright (C) 2018 - Finn Turner
# run a first function to ask for input
connect() {
echo Google Home Command Prompt
echo version 0.20 beta1
echo written by Finn Turner \<finn@innervisions.nz\>
echo "
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
"
read -p "Enter the host name or IP address of your Google Home or compatible speaker: " Host
echo attempting to connect with $Host - on port 8008.
curl http://$Host:8008/ 2>/tmp/curl
if [ $? != 0 ]; then
echo Failed to connect to your google home. CURL returned error:
echo $(cat /tmp/curl)
echo please check the google home\'s IP address and network status and try again.
exit
fi
# we assume the connection succeeded.
echo negotiating connection with $Host...
export HostName=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g')
export Version=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=build_info" 2>/dev/null|python -m json.tool|grep system_build|awk '{print $2}'|sed -e 's/\"/ /g')

echo connected to $(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g') at $Host - System version $Version
}
ReadLoop() {
read -p "{$HostName} GHCP >" a b c d e f g h i j k l
ExecLoop
}
ExecLoop() {
if [[ -n $a ]]; then
if [[ $a = "?" ]]; then
echo welcome to Google Home Command Prompt \(GHCP\).
echo this is pre-beta, so right now, you must type full http/1.1 \"GET\" or \"POST\" entrys, in the form \"method url json-data\".
echo in later versions, I will add a more complete shell for configuring the device.
ReadLoop
fi
if [[ $a = "exit" ]]; then
read -n 1 -p "Really exit GHCP [y|n]?" resp
printf "\n"
if [[ $resp = "y" ]]; then
echo Disconnecting from $HostName \($Host\).
sleep 1
echo done
exit
fi
fi
if [[ $a = "http-post" ]]; then
if [[ -z $b ]]; then
echo URL needs to be set - for example setup/assistant/alarms
ReadLoop
fi
if [[ -z $c ]]; then
echo JSON needs to be set - for example {"volume":0}
ReadLoop
fi
curl -d "$c $d $e $f $g $h $i $j $k $l" -H "Content-Type: application/json" -X POST http://$Host:8008/$b&&printf '\n'
ReadLoop
fi
if [[ $a = "http-get" ]]; then
if [[ -z $b ]]; then
echo URL needs to be set - for example setup/assistant/alarms
ReadLoop
fi
curl  -i -H "Content-Type: application/json" -X GET http://$Host:8008/$b&&printf '\n'
ReadLoop
fi

if [[ $a = "request" ]]; then
if [[ $b = "reboot" ]]; then
if [[ $c = "now" ]]; then
echo notice: rebooting $HostName \($Host\) with NO WARNING!
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
echo lost connection to $Host.
exit
fi
if [[ -z $c ]]; then
echo =====Warning=====
echo
echo
read -n 1 -p "$HostName will be rebooted. This will stop any voice interactions, cast sessions, etc. Proceed? {Y|N}" resp
if [[ $resp = "y" ]]; then
printf "\n"
echo restarting.
sleep 1
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
sleep 1
echo lost connection to $Host.
exit
fi
printf "\n"
echo reboot canceled.
ReadLoop
fi
fi
fi

echo $a: not a recognised method or command
fi
ReadLoop
}

connect
ReadLoop