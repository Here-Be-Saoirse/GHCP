# GHCP
Google Home Command Prompt - a basic shell for the Google Home and other compatible hardware
## Compatible devices

GHCP works on, of course, all Google Home devices and compatible speakers. It *should* also work with chromecasts and any other device that implements this same Google Home app / Google Cast app API

## Dependancies

GHCP requires the following on a linux system to function:

* curl
* bash (version => 4.0)
* python (version => 2.6 with the json.tool module)
* nodejs (with the castnow module)

## Usage

At the moment, you'll need to consult https://rithvikvibhu.github.io/GHLocalApi/ for API documentation, and type your commands in the form method uri values, like this:
post setup/reboot {"params": "now"}

## to do

* Implement a juniper/Vyatta-like shell for this, instead of requiring the user to know raw HTTP REST API commands.

