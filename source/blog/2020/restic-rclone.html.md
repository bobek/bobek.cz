---
title: Backups with restic and rclone
subtitle: Encrypted local and cloud backups
category: computers
date: 2020-03-03
---

I have started using [restic](https://restic.net/) backup about 2 years ago. I have learned recently, that some of my colleagues are not aware of its existence or not aware of tight integration with [rclone](https://rclone.org/). These two are a powerful combo, allowing for encrypted local and cloud backups with easy.

I also needed to recover from backups multiple times already, so even this part of backup strategy is working :)

## Restic

Restic is super *easy* to use. It is *secure* as it assumes that storage of the backup is untrusted by default. Backups are *encrypted* with  AES-256 in counter mode and authentication is done using Poly1305-AES. Checkout [Filippo's article](https://blog.filippo.io/restic-cryptography/) for a deeper look into the restic security model. It is quite *fast*. Restic needs under 4 minutes to go through my 366GB home. `rsync` needed something like 20-30 minutes to do the same job.

I am using restic with two storage backends -- `sftp` and `rclone`. Mode of operation is still the same, only what changes (from the user's perspective is URL).

## Getting started

After you install `restic`, you need to initialize your storage repository. It is as simple as:

```
~ ❯ restic -r sftp:bobek@klobouk:/klobouk/backups/restic init
enter password for new repository: 
enter password again: 
created restic repository 0507dc2c01 at sftp:bobek@klobouk:/klobouk/backups/restic

Please note that knowledge of your password is required to access
the repository. Losing your password means that your data is
irrecoverably lost.
```

Where `sftp:bobek@klobouk:/klobouk/backups/restic` is a repository URL. As you would guess

  - `sftp` is a protocol to be used (`sftp` in this case)
  - `bobek` is a username used for establishing connection
  - `klobouk` is a server name (ip address, FQDN, alias from the ssh_config, basically anything you can ssh/sftp to)
  - `/klobouk/backups/restic` is the destination path for the repository on the server side

## Making backup

Making a snapshot (incremental backup) is question of using `backup` command. You can pass additional arguments, such as `-e` for filtering out certain paths. Below is example of backing up my home:

```
~ ❯ restic -r sftp:bobek@klobouk:/klobouk/backups/restic backup -e ~/Movies ~/
Enter passphrase for key '/home/bobek/.ssh/id_rsa4096': 
enter password for repository: 
repository 0507dc2c01 opened successfully, password is correct

Files:        6941 new,  2045 changed, 2041192 unmodified
Dirs:            0 new,     1 changed,     0 unmodified
Added to the repo: 2.609 GiB

processed 2050178 files, 365.919 GiB in 3:44
snapshot 72217508 saved
```

You can check your snapshots with `snapshots` command, such as

```
~ ❯ restic -r sftp:bobek@klobouk:/klobouk/backups/restic snapshots                
enter password for repository:
repository 0507dc2c01 opened successfully, password is correct
ID        Time                 Host        Tags        Paths
------------------------------------------------------------------
41a3d112  2019-11-16 17:23:12  bobek                   /home/bobek
7816d840  2019-11-23 08:14:47  bobek                   /home/bobek
7788586b  2019-12-01 21:58:40  bobek                   /home/bobek
// removed bunch of lines to improve readability of the article
fda51794  2020-03-02 22:37:36  bobek                   /home/bobek
72217508  2020-03-03 09:20:54  bobek                   /home/bobek
------------------------------------------------------------------
56 snapshots
```

### Pruning restic repository

Your backup repository will grow indefinitely as retention policy is not part of the `backup` command. You can use `forget` command for that. As you can see, I have not ran it for a while. Let's fix that.

I am going to do it slightly differently this time and ssh to the server hosting the repository, so I will make all IO operations local (you can still use `sftp:...` with no problem).

```
bobek@klobouk:~$ restic -r /klobouk/backups/restic forget --keep-daily 7 --keep-weekly 10 --prune --cleanup-cache
enter password for repository:
repository 0507dc2c01 opened successfully, password is correct
Applying Policy: keep the last 7 daily, 10 weekly snapshots
keep 15 snapshots:
ID        Time                 Host        Tags        Reasons          Paths
-----------------------------------------------------------------------------------
cadfc8cc  2020-01-05 23:38:23  bobek                   weekly snapshot  /home/bobek
1f6bd29f  2020-01-11 22:56:46  bobek                   weekly snapshot  /home/bobek
2cfaf041  2020-01-19 20:05:58  bobek                   weekly snapshot  /home/bobek
b222742c  2020-01-26 23:59:14  bobek                   weekly snapshot  /home/bobek
0dbcbc46  2020-02-02 21:18:13  bobek                   weekly snapshot  /home/bobek
8c1ad6e8  2020-02-08 14:11:41  bobek                   weekly snapshot  /home/bobek
1794a66f  2020-02-16 23:05:10  bobek                   weekly snapshot  /home/bobek
bb3abe88  2020-02-23 23:22:54  bobek                   weekly snapshot  /home/bobek
e4f2f56c  2020-02-24 21:16:06  bobek                   daily snapshot   /home/bobek
9940a28b  2020-02-25 21:39:12  bobek                   daily snapshot   /home/bobek
df5bab63  2020-02-26 21:23:02  bobek                   daily snapshot   /home/bobek
b8d11888  2020-02-27 23:41:14  bobek                   daily snapshot   /home/bobek
272d9e5e  2020-02-28 17:19:45  bobek                   daily snapshot   /home/bobek
                                                       weekly snapshot
fda51794  2020-03-02 22:37:36  bobek                   daily snapshot   /home/bobek
72217508  2020-03-03 09:20:54  bobek                   daily snapshot   /home/bobek
                                                       weekly snapshot
-----------------------------------------------------------------------------------
15 snapshots

remove 41 snapshots:
ID        Time                 Host        Tags        Paths      
------------------------------------------------------------------
41a3d112  2019-11-16 17:23:12  bobek                   /home/bobek
7816d840  2019-11-23 08:14:47  bobek                   /home/bobek
// again, removed bunch of lines here
c8f29801  2020-03-02 07:12:00  bobek                   /home/bobek
4a7085c1  2020-03-02 21:03:36  bobek                   /home/bobek
------------------------------------------------------------------
41 snapshots
41 snapshots have been removed, running prune
```

You can run `forget` without a `--prune` and it will be quick as it only marks snapshots for removal. The actual removal of data and compaction of the repository can be also achieved with a separate `prune` command. Just be aware, that prune can take a considerable amount of time.

```
bobek@klobouk:~$ du -sh /klobouk/backups/restic
587G    /klobouk/backups/restic

bobek@klobouk:~$ restic -r /klobouk/backups/restic prune --cleanup-cache
enter password for repository:
repository 5a4fef57 opened successfully, password is correct
counting files in repo
building new index for repo
[1:10:38] 100.00%  121521 / 121521 packs
repository contains 121521 packs (2995676 blobs) with 577.392 GiB
processed 2995676 blobs: 0 duplicate blobs, 0 B duplicate
load all snapshots
find data that is still in use for 15 snapshots
[7:16] 100.00%  15 / 15 snapshots
found 2294461 of 2995676 data blobs still in use, removing 701215 blobs
will remove 0 invalid files
will delete 27364 packs and rewrite 14807 packs, this frees 172.604 GiB
[2:27:26] 100.00%  14807 / 14807 packs rewritten
counting files in repo
[37:10] 100.00%  85892 / 85892 packs
finding old index files
saved new indexes as [82c9a37f 5acc102a d5daaa0c 4a5dee08 881d6187 e9dfa06e 5bf9bf27 a3b85e96 daf45279 b56cc75e 95ef84d2 7e39afc3 9f10a455 ea80a8e9 b65b4106 6def21e2 c6ea3aae c0b30616 bb03b1eb f9c4261c 2babd31c e7d80fa8 8a5b5e47 984d8a78 c3275bb3 071e64a9 c97bb60c f263321e 67629707]
remove 125 old index files
[26:01] 100.00%  42171 / 42171 packs deleted
done

bobek@klobouk:~$ du -sh /klobouk/backups/restic
412G    /klobouk/backups/restic
```

### Recovery

Let's restore some data. Frequently, I don't need a recovery of complete backup (like complete home), but rather some particular directory or file. Something like -- I've just crashed my Firefox, lost all the open tabs and want to restore the complete Firefox directory.

1. Use `snapshots` to figure ID of snapshot we want to recover from. Let's pick the latest from our example, which is `72217508` at our example above.
1. User `restore` to get files from that snapshot. I can look something like

```
~ ❯ restic -r sftp:bobek@klobouk:/klobouk/backups/restic restore 72217508  --target /tmp/restore-firefox --include /home/bobek/.mozilla/firefox
enter password for repository:
repository 0507dc2c01 opened successfully, password is correct
restoring <Snapshot 72217508 of [/home/bobek] at 2020-03-03 09:20:54.744399448 +0100 CET by bobek@bobek> to /tmp/restore
```

And we have our files under `/tmp/restore/home/bobek/.mozilla/firefox` as expected, with a proper file mode bits etc.

### Locking

`restic` locks the repo when working with it. It will tell you when and who locked it. For example:

```
~ ❯ restic -r sftp:bobek@klobouk:/klobouk/backups/restic snapshots
enter password for repository:
repository 0507dc2c01 opened successfully, password is correct
Fatal: unable to create lock in backend: repository is already locked exclusively by PID 18172 on klobouk by bobek (UID 1000, GID 1000)
lock was created at 2020-03-03 09:48:29 (1h37m6.789848817s ago)
storage ID 9e313963
```

In cases, where you are sure that process which acquired lock is already dead, you may need to use `unlock` command. It is also a good idea to run `restic check` to verify consistency of the repository afterwards.

## rclone

`rclone` is like `rsync` for cloud. It supports usual suspects (Amazon S3, Google Drive, Dropbox) but also a lot of others.

I will use Google Drive as an example. Just follow the [rclone GDrive documentation](https://rclone.org/drive/) to set it up. You need to pick a name for your configuration. I have used `gdrive`, so after everything is done, you can issues

```
~ ❯ rclone ls gdrive:
```

to list all files on your Google Drive. No need for mounting FUSE based emulations etc. Also `rclone` behaves like `rsync` and can keep two destinations in sync. So the practical use-case, is synchronization between Dropbox and GDrive:

```
~ ❯ rclone sync -P "dropbox:/Apps/Pragmatic Bookshelf/" "gdrive:/Pragmatic Bookshelf/"
```

## restic with rclone

Finally -- let's setup backup to the cloud. And it is simple as:

  - configuring `rclone` for the cloud storage of your choice (`gdrive` in my case)
  - using `rclone` backend of the `restic` to talk to the selected storage, for example:

	```
	~ ❯ restic -r rclone:gdrive:restic init
	```
	
	which will create `restic` folder at your `gdrive`.
  - and using all the `restic` commands we have covered before, like

	```
	~ ❯	restic -r rclone:gdrive:restic backup -e .notmuch ~/Mail
	```
	to backup your `~/Mail` folder to GDrive.

## Regular backups

Backups are useful only if you do them regularly. I have initially place `restic` to my `crontab` to schedule backups. But ended up with running backups manually after all as I need to have it under a bit more control. Thus I have a script which I run before getting to bed:

```bash
#!/bin/bash
set -e

SFTP_REPO="sftp:bobek@10.0.0.250:/klobouk/backups/restic"
GDRIVE_REPO="rclone:gdrive:restic"

for i in "$@"
do
  case $i in
      --prune)
      RESTIC_PRUNE=true
      ;;
      *)
              # unknown option
      ;;
  esac
done

ssh root@10.0.0.250 'df -h /klobouk/'

read -s -t 5 -p "Enter restic password, followed by [ENTER]" RESTIC_PASSWORD && export RESTIC_PASSWORD
echo ""

restic -r "$SFTP_REPO" snapshots --cleanup-cache

if [[ ("$RESTIC_PRUNE" = true) ]]
then
  restic -r "$GDRIVE_REPO" forget --keep-daily 14 --keep-weekly 18 --prune --cleanup-cache
  restic -r "$GDRIVE_REPO" check

  restic -r "$SFTP_REPO" forget --keep-daily 7 --keep-weekly 10 --prune --cleanup-cache
  restic -r "$SFTP_REPO" check
fi

rclone sync -P "dropbox:/Apps/Pragmatic Bookshelf/" "gdrive:/Pragmatic Bookshelf/"
restic -r "$GDRIVE_REPO" backup -e .notmuch ~/Mail
restic -r "$SFTP_REPO" backup -e ~/Movies ~/

sudo poweroff
```

