#!/usr/bin/env bash

oapi_codegen="$1"
goroot="$2"
config="$3"
src="$4"

abs_go_path=$(readlink -f ./${goroot})

export PATH=${abs_go_path}/bin:$PATH

"${oapi_codegen}" --config="${config}" "${src}"
