#!/bin/bash
# GHCP - the Google Home Command Prompt
# interact with your google home over the network
# Copyright (C) 2018 - Saoirse Ó Catháin
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
echo version 0.6\(1\) on `uname`

echo written by Saoirse Ó Catháin \<saoirse@axiom-networks.org\>
echo "WARNING: this program *will probably not work* due to Google API changes."
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
echo contacting $Host...
curl http://$Host:8008/ 2>/tmp/curl
if [ $? != 0 ]; then
echo Failed to connect to your google home. CURL returned error $(cat /tmp/curl|sed -e 's/curl:\ //g'|sed -e 's/,//g'|tr -d '()'|sed -e 's/:\ /\ /g')
echo please check the google home\'s IP address and network status and try again.
exit
fi
# we assume the connection succeeded.
echo Protocol ack \(acknowledge\) received.
export publickey=$(curl http://$Host:8008/setup/eureka_info?options=detail 2>/dev/null|python -m json.tool|grep key|sed -e 's/\"//g'|sed -e 's/public_key:\ //g'|sed -e 's/,//g')
export HostName=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g')
export Version=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=build_info" 2>/dev/null|python -m json.tool|grep system_build|awk '{print $2}'|sed -e 's/\"/ /g')

#	echo connected to $(curl "http://$Host:8008/setup/eureka_info?options=detail&params=name" 2>/dev/null|sed -e 's/{\"name\":\"/ /g'|sed -e 's/\"}/ /g') at $Host - System version $Version
}
ReadLoop() {
read -p "$HostName# " a b c d e f g h i j k l
ExecLoop
}
ExecLoop() {
if [[ -n $a ]]; then
for i in {"he","hel","help","\?"}; do
if [[ $a = $i ]]; then
echo "
Commands available in this exec:
'help' or '?' - this screen.
'exit' or 'quit' - log out of the exec.
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
echo LogOut
sleep 1
exit
ReadLoop
fi
done
for i in {hp,hpo,hpos,hpost}; do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo % Error in word 2: \'URL\' parameter required.
ReadLoop
fi
if [[ -z $c ]]; then
echo % Error in word 3: \'DATA\' parameter required.
ReadLoop
fi
curl -d "$c $d $e $f $g $h $i $j $k $l" -H "Content-Type: application/json" -X POST http://$Host:8008/$b 2>/dev/null |python -m json.tool|more&&printf '\n'
ReadLoop
fi
done
for i in {hg,hge,hget}; do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo % Error in word 2: \'URL\' parameter required.
ReadLoop
fi
curl   -H "Content-Type: application/json" -X GET http://$Host:8008/$b 2>/dev/null | python -m json.tool | more &&printf '\n'
ReadLoop
fi
done
for i in {re,rel,relo,reloa,reload}; do
if [[ $a = $i ]]; then
for i in {n,no,now}; do
if [[ $b = $i ]]; then
echo `date` THE OPERATING SYSTEM ON $HostName \($Host\) IS UNDERGOING A COLD START!
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
echo lost connection to $Host.
exit
fi
done
if [[ $b = "?" ]]; then
echo "
<cr> - request cold-start confirmation
now - perform cold-start immediately
"
ReadLoop
fi

if [[ -n $b ]]; then
echo % Error in word 2: $b is not valid in the context of $a.
ReadLoop
fi
if [[ -z $b ]]; then
echo =====Warning=====
echo
echo
read -n 1 -p "$HostName will be rebooted. This will stop any voice interactions, cast sessions, etc. Proceed? {Y|N}" resp
if [[ $resp = "y" ]]; then
printf "\n"
echo `date` THE OPERATING SYSTEM ON $HostName \($Host\) IS UNDERGOING A USER-CONFIRMED COLD-START!
sleep 1
curl -d "{\"params\":\"now\"}" -H "Content-Type: application/json" -X POST http://$Host:8008/setup/reboot
sleep 1
echo lost connection to $Host.
exit
fi
printf "\n"

ReadLoop
fi
fi
done
# show:
for i in {sh,sho,show};
do
if [[ $a = $i ]]; then
if [[ -z $b ]]; then
echo % incomplete command
ReadLoop
fi
for i in {sy,sys,syst,syste,system}; do
if [[ $b = $i ]]; then
if [[ -z $c ]]; then
echo % incomplete command
ReadLoop
fi
if [[ $c = "?" ]]; then
echo "
cloudid - show the system's Cloud ID.
"
ReadLoop
fi
for i in {cl,clo,clou,cloud,cloudi,cloudid}; do
if [[ $c = $i ]]; then
export cloudid=$(curl "http://$Host:8008/setup/eureka_info?options=detail&params=" 2>/dev/null|python -m json.tool|grep \"ssdp_udn\"|sed -e 's/\"ssdp_udn\"//g'|sed -e 's/://g'|sed -e 's/\"//g'|sed -e 's/\,//g'|sed -e 's/\.//g'|awk '{print $1}')
echo $cloudid
ReadLoop
fi
done
echo % invalid command
ReadLoop
fi
done

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
for i in {co,con,conn,conne,connec,connect,connecti,connectio,connection}; do
if [[ $b = $i ]]; then
echo Connected to $Host - $HostName
ReadLoop
fi
done
for i in {pu,pub,publ,publi,public,publick,publicke,publickey}; do
if [[ $b = $i ]]; then
echo System Public Key: $publickey
ReadLoop
fi
done
for i in {pl,pla,plat,platf,platfo,platfor,platform}; do
if [[ $i = $b ]]; then
echo $(curl http://$Host:8008/setup/eureka_info?options=detail 2>/dev/null|python -m json.tool|grep manufa|sed -e 's/\"//g'|sed -e 's/manufacturer:\ //g'|sed -e 's/,//g') $(curl http://$Host:8008/setup/eureka_info?options=detail 2>/dev/null|python -m json.tool|grep model|sed -e 's/\"//g'|sed -e 's/model_name:\ //g'|sed -e 's/,//g') platform:
echo Mac address: $(curl http://$Host:8008/setup/eureka_info?options=detail 2>/dev/null|python -m json.tool|grep mac_addr|sed -e 's/\"//g'|sed -e 's/mac_address:\ //g'|sed -e 's/,//g') 
ReadLoop
fi
done
if [[ $b = "?" ]]; then
echo "
connection - show hostname and connected device
platform - show device name, serial number, etc
publickey - show the identity public key
software - show system software parameters
version - show the OS version and cast firmware revision on this device
"
ReadLoop
fi
if [[ -n $b ]]; then
echo "% invalid parameter"
ReadLoop
fi
fi
done



echo % invalid command
fi
ReadLoop
}

echo error: this program has been disabled as it is no longer functional
exit 0
#connect
#ReadLoop
