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
read -p "($HostName) GHCP#" a b c d e f g h i j k l
ExecLoop
}
ExecLoop() {
if [[ -n $a ]]; then
for i in {"he","hel","help","\?"}; do
if [[ $a = $i ]]; then
echo "
Google Home Command Prompt (GHCP) Pre-Beta.
Connected to: $Host ($HostName).
The following global commands are available (command completion, when unambiguous, is automatic):
'help' or '?' - this screen.
'exit' or 'quit' - disconnect from the device and close this program.
'hget' and 'hpost' - send raw http get and post commands to your device.


The following verbs are available:

'request' - system requests (like rebooting, disconnecting 
echo from and connecting to wi-fi networks, scanning for them, etc)

any command or verb can be followed by "?" to see all it's options.
"
ReadLoop
fi
done
for i in {exit,exi,q,qui,quit,ex}; do

if [[ $a = $i ]]; then
read -n 1 -p "Really exit GHCP [y|n]?" resp
printf "\n"
if [[ $resp = "y" ]]; then
echo Disconnecting from $HostName \($Host\).
sleep 1
echo done
exit
fi
ReadLoop
fi
done
for i in {hp,hpo,hpos,hpost}; do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo URL needs to be set - for example setup/assistant/alarms
ReadLoop
fi
if [[ -z $c ]]; then
echo JSON needs to be set - for example {"volume":0}
ReadLoop
fi
curl -d "$c $d $e $f $g $h $i $j $k $l" -H "Content-Type: application/json" -X POST http://$Host:8008/$b 2>/dev/null |python -m json.tool|less&&printf '\n'
ReadLoop
fi
done
for i in {hg,hge,hget}; do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo URL needs to be set - for example setup/assistant/alarms
ReadLoop
fi
curl   -H "Content-Type: application/json" -X GET http://$Host:8008/$b 2>/dev/null|python -m json.tool|less&&printf '\n'
ReadLoop
fi
done
for i in {re,req,requ,reque,reques,request}; do
if [[ $a = $i ]]; then
for i in {re,reb,rebo,reboo,reboot}; do
if [[ $b = $i ]]; then
for i in {n,no,now}; do
if [[ $c = $i ]]; then
echo notice: rebooting $HostName \($Host\) with NO WARNING!
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
echo lost connection to $Host.
exit
fi
done
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
done
if [[ -z $b ]]; then
echo Request: incomplete command - try \"request ?\"
ReadLoop
fi
if [[ $b = "?" ]]; then
echo Request:

printf " \t bluetooth \n"
printf " \t \t pairing \n"
printf " \t \t \t enable \n"
printf " \t \t \t disable \n"
printf " \t \t scan \n"
printf " \t \t \t results \n"
printf "\t reboot\n"
printf "\t\t now\n"
printf "\t wifi\n"
printf " \t \t scan \n"
printf " \t \t \t results\n"

ReadLoop
fi
echo $b: not valid in the context of \"request\" - try \"request ?\" for help.
ReadLoop
fi
done
echo $a: not a recognised method or command
fi
ReadLoop
}

connect
ReadLoop