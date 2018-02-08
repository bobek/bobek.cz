---
title: exim4 and multiple GMail accounts
subtitle: Split-routing based on sender address in exim4
category: hacking
tags: linux
date: 2018-02-08
cover: 2018/exim4.png
---

**mutt** is my preferred client for reading and writing mails. And I do have multiple accounts, some on my private server some on GMail (private as well as business).

Initial setup was using my private mail server as single smart host for relaying all outgoing emails. That is sub-optimal as things like DKIM and SPF are basically not working and your GMail emails looks like not legitimate.

##mutt
Configuration of mutt is fairly simple:

```
set use_envelope_from = yes
set from=”myself@privateemail.com”
folder-hook IN.company “set from=myself@company.com”
folder-hook company/* “set from=myself@company.com”
folder-hook IN.gmail “set from=myself@gmail.com”
```

The important setting is

```
set use_envelope_from = yes
```

which instructs mutt to use From address as the from at email’s envelope as well. Other lines are setting default From addresses. Making sure, that if I am at work, I will send email from my work address as well.

##exim4
I am on Debian GNU/Linux so exim4 is the default MTA. I do use postfix on servers, but exim4 is quite flexible in configuration and works well on laptop. I am using config split into multiple files (current Debian default approach).

Following changes will route exceptions, in my case emails via GMail. I will keep my previous (standard) configuration for using a smarthost.

To be able to split route emails, we need to into

  * `router` (== what to send)
  * `transport` (== where to send)
  * `authenticator` (== how to prove eligibility to send)

###router
Following code takes care of selecting emails which will need special treatment:

```
smarthost_gmail:
  condition = ${lookup {${lc:$sender_address}}lsearch{CONFDIR/gmail-accounts} {yes}{no}}
  driver = manualroute
  transport = remote_smtp_gmail
  route_list = * smtp.gmail.com
  no_more
```

Let's put this into `/etc/exim4/conf.d/router/150_exim4-config_gmail`.

As you can see, I’ve added new configuration file (`gmail-accounts`) which contains list of sender addresses which should be routed via GMail. It is just simple list:

```
myself@company.com
myself@gmail.com
```

###transport
Configuration for GMail transport is fairly simple as well.

```
remote_smtp_gmail:
  debug_print = “T: remote_smtp_gmail for $local_part@$domain”
  driver = smtp
  port = 587
  hosts_require_auth = *
  hosts_require_tls = *
```
Which is in `/etc/exim4/conf.d/transport/30_exim4-config_remote_smtp_gmail`.

###authenticator
Authentication turned to be the hardest part of the setup. exim4 allows only one `autheticator` per protocol (called `public_name`). You can add conditions via `client_condition`, but the limitation on one authenticator per `public_name` will still hold. Conditions are used as a last resort for disabling certain mechanism if you don’t like for example used encryption method. So I have ended up with this

```
HOST_PASSWDLINE=${sg{\
 ${lookup{$host}nwildlsearch{CONFDIR/passwd.client}{$value}fail}\
 }\
 {\\N[\\^]\\N}\
 {^^}\
 }
SENDER_PASSWDLINE=${sg{\
 ${lookup{${lc:$sender_address}}nwildlsearch{CONFDIR/passwd.client}{$value}fail}\
 }\
 {\\N[\\^]\\N}\
 {^^}\
 }
PASSWDLINE = ${if eq{SENDER_PASSWDLINE}{}{HOST_PASSWDLINE}{SENDER_PASSWDLINE}}

plain:
 driver = plaintext
 public_name = PLAIN
.ifndef AUTH_CLIENT_ALLOW_NOTLS_PASSWORDS
 client_send = “<; ${if !eq{$tls_out_cipher}{}\
 {^${extract{1}{:}{PASSWDLINE}}\
 ^${sg{PASSWDLINE}{\\N([^:]+:)(.*)\\N}{\\$2}}\
 }fail}”
.else
 client_send = “<; ^${extract{1}{:}{PASSWDLINE}}\
 ^${sg{PASSWDLINE}{\\N([^:]+:)(.*)\\N}{\\$2}}”
.endif
```

Which resides in `/etc/exim4/conf.d/auth/30_exim4-auth_gmail`. This configuration taps to "standard" `passwd.client` file. In our case it contains

```
myself@company.com:myself@showmax.com:app_password1
myself@gmail.com:myself@gmail.com:app_password2
*:myself@privateemail.com:secret_password
```

There is a bit of redundancy, which could have been removed. But I have decided to stick with the default format to have only one file with password.

##Final words
Hope this will help somebody to keep using awesome commandline environment for managing loads of email. I would also suggest double-checking that your exim is listening on localhost only. So it is not reachable over network:

```
dc_local_interfaces=’127.0.0.1; ::1'
```

Happy emailing!
