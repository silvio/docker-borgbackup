#!/bin/bash

source borg-env/bin/activate

SCRIPTVERSION=1

INIFILE=/B/borg-backup.ini
BACKUPREPO=""
BACKUPNAME=""
DATEAPPEND=""
DATEFORMAT=""
EXCLUDE=""
PRUNE="0"
PRUNEHOUR=""
PRUNEDAY=""
PRUNEWEEK=""
PRUNEMONTH=""
PRUNEYEAR=""
VERSION=0
VERBOSE=0

__shini_parsed () {
	case "${1}" in
		"REPO")
			[[ "${2}" == "backuprepo" ]] && export BACKUPREPO="${3}"
			[[ "${2}" == "backupname" ]] && export BACKUPNAME="${3}"
			[[ "${2}" == "dateappend" ]] && export DATEAPPEND="${3}"
			[[ "${2}" == "dateformat" ]] && export DATEFORMAT="${3}"
			;;

		"MISC")
			[[ "${2}" == "version" ]] && export VERSION=${3}
			[[ "${2}" == "verbose" ]] && export VERBOSE=${3}
			;;

		"EXCLUDE")
			pattern="${3}"
			[[ "${pattern:0:1}" == "/" ]] && pattern="/B${pattern}"
			export EXCLUDE="${EXCLUDE} --exclude ${pattern}"
			;;

		"PRUNE")
			[[ "${2}" == "enable" ]] && export PRUNE="1"
			[[ "${2}" == "hourly" ]] && export PRUNEHOUR="--keep-hourly ${3}"
			[[ "${2}" == "daily" ]] && export PRUNEDAY="--keep-daily ${3}"
			[[ "${2}" == "weekly" ]] && export PRUNEWEEK="--keep-weekly ${3}"
			[[ "${2}" == "monthly" ]] && export PRUNEMONTH="--keep-monthly ${3}"
			[[ "${2}" == "yearly" ]] && export PRUNEYEAR="--keep-yearly ${3}"
			;;

		*)
			echo "inifile problem: \$1=${1}, \$2=${2}, \$3=${3} unknown"
			;;
	esac
}

if [[ "$1" == "mybackup" ]]; then

	[[ ! -e ${INIFILE} ]] && echo "No inifile ${INIFILE}, exited" && exit 1

	source /usr/bin/shini

	shini_parse ${INIFILE}

	[[ "${SCRIPTVERSION}" != "${VERSION}" ]] && echo "scriptversion ${SCRIPTVERSION} not eqal with inifile version ${VERSION}" && exit 1

	[[ -z "${BACKUPREPO}" ]] && echo "inifile problem: no 'backuprepo' entry" && exit
	[[ -z "${BACKUPNAME}" ]] && echo "inifile problem: no 'backupname' entry" && exit

	[[ "${VERBOSE}" == "1" ]] && VERBOSE="--progress" || VERBOSE=""

	[[ -z "${DATEFORMAT}" ]] && export DATEFORMAT="+%Y-%m-%d"
	BACKUPDATE=$(date ${DATEFORMAT})

	backupname="${BACKUPNAME}"
	[[ ! -z "${DATEAPPEND}" ]] && backupname="${backupname}-${BACKUPDATE}"

	backuppathes=""
	backupdir="/backupdir"

	for i in /B/*
	do
		backuppathes="${backuppathes} ${i}"
	done

	[[ ! -e ${backupdir}/${BACKUPREPO} ]] && borg init ${backupdir}/${BACKUPREPO}

	echo ":: " borg create ${VERBOSE} --stats \
		${backupdir}/${BACKUPREPO}::${backupname} \
		${backuppathes} \
		${EXCLUDE}
	borg create ${VERBOSE} --stats \
		${backupdir}/${BACKUPREPO}::${backupname} \
		${backuppathes} \
		${EXCLUDE}

	if [[ "${PRUNE}" == "1" ]]; then
		echo ":: " borg prune --stats -v ${backupdir}/${BACKUPREPO} \
			${PRUNEDAY} \
			${PRUNEWEEK} \
			${PRUNEMONTH}
		borg prune --stats -v ${backupdir}/${BACKUPREPO} \
			${PRUNEHOUR} \
			${PRUNEDAY} \
			${PRUNEWEEK} \
			${PRUNEMONTH} \
			${PRUNEYEAR}
	fi

	exit 0
fi

borg $*
