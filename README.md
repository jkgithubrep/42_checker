# 42 checker

*42\_checker* is a script which makes it easier to check basic requirements for the projects at [42](https://www.42.fr/).

## Getting started

```
git clone https://github.com/jkgithubrep/42_checker.git 
```

## Usage

```
Usage: sh 42_checker [options] [git_repo_url/path_to_project]
Options:
 -e, --all               Check everything.
 -r, --clone             Clone repository given as parameters before checking everything.
 -h, --help              Print this message and exit.
 -a, --author            Check for author file.
 -n, --norminette        Check norminette.
 -d, --headers           Check matching headers with file name.
 -m, --makefiles         Check makefiles (relink, wildcards).
 -c, --contrib           Check project contributors.
 -g, --git-logs          Check git logs.

```

Options have to be written separately.

**Example**:
To check *author file*, *norminette* and *makefiles*, write:
```
sh 42_checker -a -n -m /path/to/project
```

## Author

by **jkettani**
