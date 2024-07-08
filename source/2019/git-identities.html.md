---
title: Simple GIT identities (overrides in general) management
category: computers
date: 2019-07-26
---

I need to be committing intro different repositories under different user identities. To Open Source ones with my private email, while using work email for work-related commits/repos.

Typically, you would use repo-specific identities. For example (my work repo):

```bash
git config user.name "Antonin Kral"
git config user.email antonin.kral@dtone.com
```
Now, that is error-prone and painful. I have discovered a neat feature of git (since 2.13) which allows for conditional inclusion of configuration files. Let's assume the following configuration files:

```toml
# ~/.gitconfig

[user]
	email = a.kral@bobek.cz
	name = Antonin Kral

[includeIf "gitdir:~/Sources/dtone/"]
  path = .gitconfig_dtone
```

```toml
# ~/.gitconfig_dtone

[user]
   name = Antonin Kral
   email = antonin.kral@dtone.com
```

And that's it. Every time I work with repo, which is cloned under `~/Sources/dtone`, my identity will be automatically changed to work one. This is not limited to identities; you can override anything you want.
