#!/usr/bin/env bash
# This program installs the latest release of the Git Large File Storage in a snapcraft part installtree
# 林博仁 © 2018

## Makes debuggers' life easier - Unofficial Bash Strict Mode
## BASHDOC: Shell Builtin Commands - Modifying Shell Behavior - The Set Builtin
set \
	-o errexit \
	-o errtrace \
	-o nounset \
	-o pipefail

## Runtime Dependencies Checking
declare\
	runtime_dependency_checking_result=still-pass\
	required_software

for required_command in \
	basename \
	dirname \
	git \
	grep \
	head \
	mktemp \
	realpath \
	rm \
	sort \
	tar \
	wget; do
	if ! command -v "${required_command}" &>/dev/null; then
		runtime_dependency_checking_result=fail

		case "${required_command}" in
			basename \
			|dirname \
			|realpath \
			|rm \
			|sort)
				required_software='GNU Coreutils'
				;;
			git)
				required_software='Git'
				;;
			grep)
				required_software='GNU Grep'
				;;
			tar)
				required_software='GNU Tar'
				;;
			wget)
				required_software='GNU Wget'
				;;
			*)
				required_software="${required_command}"
				;;
		esac

		printf -- \
			'Error: This program requires "%s" to be installed and its executables in the executable searching paths.\n' \
			"${required_software}" \
			1>&2
		unset required_software
	fi
done; unset required_command required_software

if [ "${runtime_dependency_checking_result}" = fail ]; then
	printf -- \
		'Error: Runtime dependency checking fail, the progrom cannot continue.\n' \
		1>&2
	exit 1
fi; unset runtime_dependency_checking_result

## Non-overridable Primitive Variables
## BASHDOC: Shell Variables » Bash Variables
## BASHDOC: Basic Shell Features » Shell Parameters » Special Parameters
if [ -v 'BASH_SOURCE[0]' ]; then
	RUNTIME_EXECUTABLE_PATH="$(realpath --strip "${BASH_SOURCE[0]}")"
	RUNTIME_EXECUTABLE_FILENAME="$(basename "${RUNTIME_EXECUTABLE_PATH}")"
	RUNTIME_EXECUTABLE_NAME="${RUNTIME_EXECUTABLE_FILENAME%.*}"
	RUNTIME_EXECUTABLE_DIRECTORY="$(dirname "${RUNTIME_EXECUTABLE_PATH}")"
	RUNTIME_COMMANDLINE_BASECOMMAND="${0}"
	# We intentionally leaves these variables for script developers
	# shellcheck disable=SC2034
	declare -r \
		RUNTIME_EXECUTABLE_PATH \
		RUNTIME_EXECUTABLE_FILENAME \
		RUNTIME_EXECUTABLE_NAME \
		RUNTIME_EXECUTABLE_DIRECTORY \
		RUNTIME_COMMANDLINE_BASECOMMAND
fi
declare -ar RUNTIME_COMMANDLINE_ARGUMENTS=("${@}")

fetch_latest_git_lfs_release_tag(){
	# How to get list of latest tags in remote git? - Stack Overflow
	# http://stackoverflow.com/questions/20734181/how-to-get-list-of-latest-tags-in-remote-git
	#Seems to be false-positive
	#shellcheck disable=SC2026
	git ls-remote https://github.com/git-lfs/git-lfs\
		| grep -o 'refs/tags/v[0-9]*\.[0-9]*\.[0-9]*' \
		| sort -r\
		| head --lines=1\
		| grep -o '[^\/]*$'
	return 0
}; readonly -f fetch_latest_git_lfs_release_tag

translate_snapcraft_arch_triplet_to_git_lfs_arch(){ # _arch_triplet_name
	if test $# -ne 1; then
		printf -- \
			'%s: FATAL: Argument quantity mismatch.\n' \
			"${FUNCNAME[0]}" \
			1>&2
		exit 1
	fi

	case "${SNAPCRAFT_ARCH_TRIPLET}" in
		i386-linux-gnu)
			printf 386
		;;
		x86_64-linux-gnu)
			printf amd64
		;;
		arm-linux-gnueabihf)
			printf armhf
		;;
		aarch64-linux-gnu)
			printf arm64
		;;
		*)
			printf -- \
				'%s: Error: Unsupported arch triplet.\n' \
				"${FUNCNAME[0]}" \
				1>&2
			return 1
		;;
	esac
	return 0
}; readonly -f translate_snapcraft_arch_triplet_to_git_lfs_arch

declare workdir
workdir="$(
	mktemp \
		--directory \
		--tmpdir \
		"${RUNTIME_EXECUTABLE_NAME}.XXX"
)"
declare -r workdir

declare global_keep_temp_files=false

init(){
	if ! process_commandline_arguments; then
		printf -- \
			'Error: Invalid command-line parameters.\n' \
			1>&2

		printf '\n' # separate error message and help message
		print_help
		exit 1
	fi

	for snapcraft_environment_variable in \
		SNAPCRAFT_ARCH_TRIPLET \
		SNAPCRAFT_PART_INSTALL; do

		if ! test -v "${snapcraft_environment_variable}"; then
			printf -- \
				'%s: FATAL: This program requires %s environmental variable to be set.\n' \
				"${RUNTIME_EXECUTABLE_NAME}" \
				"${snapcraft_environment_variable}" \
				1>&2
			exit 1
		fi
	done; unset snapcraft_environment_variable

	declare git_lfs_arch
	git_lfs_arch="$(translate_snapcraft_arch_triplet_to_git_lfs_arch "${SNAPCRAFT_ARCH_TRIPLET}")"
	declare -r git_lfs_arch

	case "${git_lfs_arch}" in
		386\
		|amd64)
			: # Supported
		;;
		*)
			printf -- \
				'%s: Arch not supported, installation skipped.' \
				"${RUNTIME_EXECUTABLE_NAME}"
			exit 0
		;;
	esac

	declare latest_release_tag
	latest_release_tag="$(fetch_latest_git_lfs_release_tag)"
	readonly latest_release_tag

	wget \
		--directory-prefix="${workdir}" \
		https://github.com/git-lfs/git-lfs/releases/download/"${latest_release_tag}"/git-lfs-linux-"${git_lfs_arch}"-"${latest_release_tag:1}".tar.gz

	tar\
		--directory="${workdir}" \
		--extract \
		--file "${workdir}"/git-lfs-linux-"${git_lfs_arch}"-"${latest_release_tag:1}".tar.gz \
		--verbose

	sed \
		--expression='s/git lfs install//g' \
		--in-place \
		"${workdir}"/git-lfs-"${latest_release_tag:1}"/install.sh

	env \
		PREFIX="${SNAPCRAFT_PART_INSTALL}" \
		"${workdir}"/git-lfs-"${latest_release_tag:1}"/install.sh

	exit 0
}; declare -fr init

print_help(){
	# Backticks in help message is Markdown's <code> markup
	# shellcheck disable=SC2016
	{
		printf '# Help Information for %s #\n' \
			"${RUNTIME_COMMANDLINE_BASECOMMAND}"
		printf '## SYNOPSIS ##\n'
		printf '* `"%s" _command-line_options_`\n\n' \
			"${RUNTIME_COMMANDLINE_BASECOMMAND}"

		printf '## COMMAND-LINE OPTIONS ##\n'
		printf '### `-d` / `--debug` ###\n'
		printf 'Enable script debugging\n\n'

		printf '### `-n` / `--no-clean` ###\n'
		printf "Don't keep temp files, useful for debugging.\\n\\n"

		printf '### `-h` / `--help` ###\n'
		printf 'Print this message\n\n'
	}
	return 0
}; declare -fr print_help;

process_commandline_arguments() {
	if [ "${#RUNTIME_COMMANDLINE_ARGUMENTS[@]}" -eq 0 ]; then
		return 0
	fi

	# Modifyable parameters for parsing by consuming
	local -a parameters=("${RUNTIME_COMMANDLINE_ARGUMENTS[@]}")

	# Normally we won't want debug traces to appear during parameter parsing, so we add this flag and defer its activation till returning(Y: Do debug)
	local enable_debug=N

	while true; do
		if [ "${#parameters[@]}" -eq 0 ]; then
			break
		else
			case "${parameters[0]}" in
				--debug \
				|-d)
					enable_debug=Y
					global_keep_temp_files=true
					;;
				--help \
				|-h)
					print_help;
					exit 0
					;;
				--no-clean \
				|-n)
					global_keep_temp_files=true
					;;
				*)
					printf -- \
						'%s: Error: Unknown command-line argument "%s"\n' \
						"${FUNCNAME[0]}" \
						"${parameters[0]}" \
						>&2
					return 1
					;;
			esac
			# shift array by 1 = unset 1st then repack
			unset 'parameters[0]'
			if [ "${#parameters[@]}" -ne 0 ]; then
				parameters=("${parameters[@]}")
			fi
		fi
	done

	if [ "${enable_debug}" = Y ]; then
		trap 'trap_return "${FUNCNAME[0]}"' RETURN
		set -o xtrace
	fi
	return 0
}; declare -fr process_commandline_arguments

## Traps: Functions that are triggered when certain condition occurred
## Shell Builtin Commands » Bourne Shell Builtins » trap
trap_errexit(){
	printf \
		'An error occurred and the script is prematurely aborted\n' \
		1>&2
	return 0
}; declare -fr trap_errexit; trap trap_errexit ERR

trap_exit(){
	if test "${global_keep_temp_files}" = false; then
		rm \
			--force \
			--recursive \
			"${workdir}"
	fi
	return 0
}; declare -fr trap_exit; trap trap_exit EXIT

trap_return(){
	local returning_function="${1}"

	printf \
		'DEBUG: %s: returning from %s\n' \
		"${FUNCNAME[0]}" \
		"${returning_function}" \
		1>&2
}; declare -fr trap_return

trap_interrupt(){
	printf '\n' # Separate previous output
	printf \
		'Recieved SIGINT, script is interrupted.' \
		1>&2
	return 1
}; declare -fr trap_interrupt; trap trap_interrupt INT

init "${@}"

