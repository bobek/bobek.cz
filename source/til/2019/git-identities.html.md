---
title: Simple GIT identities (overrides in general) management
category: til
date: 2019-07-26
tags: ["git", "shell"]
---

I need to be committing intro different repositories under different user identities. To Open Source ones with my private email, while using work email for work-related commits/repos.

Typically, you would use repo-specific identities. For example (my work repo):

```shell
git config user.name "Antonin Kral"
git config user.email antonin.kral@workdomain.com
```

Now, that is error-prone and painful. I have discovered a neat feature of git (since 2.13) which allows for conditional inclusion of configuration files. Let's assume the following configuration files:

```ini
# ~/.gitconfig

[user]
  email = a.kral@bobek.cz
  name = Antonin Kral

[includeIf "gitdir:~/Sources/work/"]
   path = .gitconfig_work
```

Alternative approach using [`hasconfig:remote.*.url`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-codehasconfigremoteurlcode). I've learned about this option from [Benji](https://www.benji.dog/articles/git-config/). It even works when cloning!

```ini
# ~/.gitconfig

[user]
  email = a.kral@bobek.cz
  name = Antonin Kral

[includeIf "hasconfig:remote.*.url:git@gitlab.com:work_org/**"]
   path = .gitconfig_work
```

And finally the actual config override with work specific configuration:

```ini
# ~/.gitconfig_work

[user]
   name = Antonin Kral
   email = antonin.kral@workdomain.com

[core]
  sshCommand = "ssh -i ~/.ssh/work_git_key -F /dev/null"
```

And that's it. Every time I work with repo, which is cloned under `~/Sources/work`, my identity will be automatically changed to work one. This is not limited to identities; you can override anything you want.
