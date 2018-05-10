#!/bin/bash
# GHCP - the Google Home Command Prompt
# interact with your google home over the network
# Copyright (C) 2018 - Finn Turner
# run a first function to ask for input
function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"min "$sec"sec
}
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
read -p "Device IP address: " Host
#echo attempting to connect with $Host - on port 8008.
curl http://$Host:8008/ 2>/tmp/curl
if [ $? != 0 ]; then
echo Failed to connect to your google home. CURL returned error:
echo $(cat /tmp/curl)
echo please check the google home\'s IP address and network status and try again.
exit
fi
# we assume the connection succeeded.
#echo negotiating connection with $Host...
export HostName=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g')
export Version=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=build_info" 2>/dev/null|python -m json.tool|grep system_build|awk '{print $2}'|sed -e 's/\"/ /g')

#	echo connected to $(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g') at $Host - System version $Version
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
reload - restart the device (with or without warning)


The following verbs are available:

show - show system information

Any command or verb can be followed by "?" to see all it's options.
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
for i in {re,rel,relo,reloa,reload}; do
if [[ $a = $i ]]; then
for i in {n,no,now}; do
if [[ $b = $i ]]; then
echo notice: rebooting $HostName \($Host\) with NO WARNING!
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
echo lost connection to $Host.
exit
fi
done
if [[ $b = "?" ]]; then
echo "
<cr>
now - skip the warning text
"
ReadLoop
fi

if [[ -n $b ]]; then
echo "unknown parameter $b to command reload - try reload ?"
ReadLoop
fi
if [[ -z $b ]]; then
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
# show:
for i in {sh,sho,show};
do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo "show: incomplete command - try show ?"
ReadLoop
fi
for i in {ver,vers,versi,versio,version}; do
if [[ $b = $i ]]; then
export cast_version=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=" 2>/dev/null|python -m json.tool|grep \"cast_build_revision\"|sed -e 's/\"cast_build_revision\"/ /g'|sed -e 's/:/ /g'|sed -e 's/\"/ /g'|sed -e 's/\,/ /g'|sed -e 's/ *//g')
export version_track=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=" 2>/dev/null|python -m json.tool|grep \"release_track\"|sed -e 's/\"release_track\"/ /g'|sed -e 's/:/ /g'|sed -e 's/\"/ /g'|sed -e 's/\,/ /g'|sed -e 's/ *//g')
export uptime=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=" 2>/dev/null|python -m json.tool|grep \"uptime\"|sed -e 's/\"uptime\"/ /g'|sed -e 's/:/ /g'|sed -e 's/\"/ /g'|sed -e 's/\,/ /g'|sed -e 's/\./ /g'|awk '{print $1}')
export uptime_friendly=$(show_time $uptime)
echo "
$HostName:
System build revision: $Version
cast software version $cast_version ($version_track)
Device up $uptime_friendly
"
ReadLoop
fi
done
if [[ $b = "?" ]]; then
echo "
version
"
ReadLoop
fi
if [[ -n $b ]]; then
echo "$b: not valid in the context of show - try show ?"
ReadLoop
fi
fi
done



echo $a: not a recognised method or command
fi
ReadLoop
}

connect
ReadLoop