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

```ini
# ~/.gitconfig_work

[user]
   name = Antonin Kral
   email = antonin.kral@workdomain.com
```

And that's it. Every time I work with repo, which is cloned under `~/Sources/work`, my identity will be automatically changed to work one. This is not limited to identities; you can override anything you want.
