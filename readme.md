
This docker project brings the small and simple backup solution [borg] to your
computer.

[borg]: https://borgbackup.github.io/

# How to use

## test this image

```bash
$ docker run -ti docker-borgbackup -h
usage: borg [-h]
            {serve,init,check,change-passphrase,create,extract,rename,delete,list,mount,info,prune,help}
             ...

Borg 0.24.0+17.g3100fac - Deduplicated Backups

optional arguments:
  -h, --help            show this help message and exit

Available commands:
  {serve,init,check,change-passphrase,create,extract,rename,delete,list,mount,info,prune,help}
```

Maybe its better to put `docker run -ti docker-borgbackup` in a `borg`-alias or
script for the shell.

### Example

```bash
$ docker run --rm -ti -v /storage/backup:/backupdir -v /home/xxx:/B/xxx docker-borgbackup init /backupdir
[...]
$ docker run --rm -ti -v /storage/backup:/backupdir -v /home/xxx:/B/xxx docker-borgbackup create -p /backupdir::/home/xxx /B/xxx
[...]
$ docker run --rm -ti -v /tmp/backup:/backupdir -v /development/gitarchives/sbc:/B/sbc docker-borgbackup list /backupdir
/xxx                                 Thu Aug 13 12:41:40 2015
```

# Automatic backup

This Dockerfile is arranged to do automatic backups. For this the option
`mybackup` is added.

## concept

We run borg in a container which needs access to the directories/files which
need a backup and the directory in which we put the backup, furthermore we need
a configuration file for automation of the backup process via a cron job. For
this we use docker specific options.

All folders or files and the configuration file for the backup have to be
mounted in the `/B` folder.

The store folder for the backup have to be in `/backupdir`.

## `ini`-parameter

The file must be named `borg-backup.ini`. The file must have `MISC` and
`REPO` and could have `PRUNE` and `EXCLUDE` sections.

In this repository we have an `ini`-file example.

### MISC

Two options exists in the `MISC` section. One is `version` and has to be the
same as the in-docker `mybackup` script. And the second option is for `verbose`
output.

### REPO

You mount your backup folder into the `backupdir` folder of the docker image.
Your backup repositories are accessible through the `backuprepo` option. And
the backup archives are generated from the `backupname`, `dateappend` and
`dateformat` options.

### PRUNE

You can disable pruning via `enable` option. The `borg` options for
`--keep-hourly`, `--keep-daily`, `--keep-weekly`, `--keep-monthly` and
`--keep-yearly` have a corresponding option via the `ini`-file options
`hourly`, `daily`, `weekly`, `monthly` and `yearly`.

### EXCLUDE

All entries in the `EXCLUDE` section are added to the `--exclude` option at
archive creation time. The name of the `ini`-file entries are regardless.

## example

```bash
$ docker run -ti -v /etc:/B/etc -v ~/borg-backup.ini:/B/borg-backup.ini -v /mnt/ext/BACKUP:/backupdir docker-borgbackup init /backupdir
$ docker run -ti -v /etc:/B/etc -v ~/borg-backup.ini:/B/borg-backup.ini -v /mnt/ext/BACKUP:/backupdir docker-borgbackup create /backupdir::xxx /B/...
```
