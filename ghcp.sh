#!/bin/bash
# GHCP - the Google Home Command Prompt
# interact with your google home over the network
# run a first function to ask for input
connect() {
echo Google Home Command Prompt
echo version 0.1
echo written by Finn Turner \<finn@innervisions.nz\>
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
read -p "{$HostName} GHCP >" method url values
ExecLoop
}
ExecLoop() {
if [[ -n $method ]]; then
if [[ $method = "?" ]]; then
echo welcome to Google Home Command Prompt \(GHCP\).
echo this is pre-beta, so right now, you must type full http/1.1 \"GET\" or \"POST\" entrys, in the form \"method url json-data\".
echo in later versions, I will add a more complete shell for configuring the device.
ReadLoop
fi
if [[ $method = "exit" ]]; then
read -n 1 -p "Really exit GHCP [y|n]?" resp
printf "\n"
if [[ $resp = "y" ]]; then
echo Disconnecting from $HostName \($Host\).
sleep 1
echo done
exit
fi
fi
if [[ $method = "do" ]]; then
echo do $url $values not implemented.
echo \"do\" is not implemented at all.
ReadLoop
fi
if [[ $method = "post" ]]; then
if [[ -z $url ]]; then
echo URL needs to be set - for example setup/assistant/alarms
ReadLoop
fi
if [[ -z $values ]]; then
echo JSON needs to be set - for example {"volume":0}
ReadLoop
fi
#export values=$(echo $values|sed -e 's/\"/\\\"/g')
echo "curl -i -d '$values' -H "Content-Type: application/json" -X POST http://$Host:8008/$url&&printf '\n'"
curl -i -d "$values" -H "Content-Type: application/json" -X POST http://$Host:8008/$url&&printf '\n'

ReadLoop
fi
echo $method: not a recognised method or command
fi
#curl -d '$values' -H "Content-Type: application/json" -X $method http://$Host:8008/$url
ReadLoop
}

connect
ReadLoop