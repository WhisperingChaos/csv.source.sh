#!/bin/bash

sourcer_sh_compose(){
	local -r compPath="$(dirname "${BASH_SOURCE[0]}")"

	source  "$compPath/./base/sourcer.source.sh"
}

sourcer_sh_compose
