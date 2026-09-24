# gptel-presets

Define [gptel](https://github.com/karthink/gptel) presets in Markdown files with
YAML frontmatter.

The default preset directory is `gptel-presets` under `user-emacs-directory`
(typically `~/.emacs.d/gptel-presets` on Unix-like systems, and the
corresponding Emacs user directory on other platforms).

For example, `coding.md` can contain:

```markdown
---
description: Python coding assistant
model: gpt-oss-20b
temperature: 0.2
---
You are an experienced Python coding assistant.

Write clear, idiomatic, maintainable Python. Follow the project's existing
style and conventions, prefer simple solutions, and explain important
trade-offs briefly.
```

Load it with:

```elisp
(gptel-presets-load-directory)
```

See [gptel's Option Preset](https://github.com/karthink/gptel#option-presets)
documentation.


## Installation from GitHub

With Emacs 30.1 or newer, `package-vc` can install the package directly from
GitHub. Make sure GNU ELPA is configured so the `yaml` dependency can be
resolved, then evaluate:

```elisp
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(package-initialize)
(package-refresh-contents)
(package-vc-install
 "https://github.com/hg-jt/gptel-presets")
```

After installation, load the package and your preset files:

```elisp
(gptel-presets-load-directory)
```

The `gptel-presets-load-directory` command is autoloaded when the package is
installed through `package.el` or `package-vc`. If you load the source file
manually, use `(require 'gptel-presets)` first.

The filename becomes the preset name, YAML fields become gptel preset keywords,
and the Markdown body becomes `:system`. The `model` and `temperature` values are
converted from YAML strings to symbols, as expected by gptel.

The package depends on the GNU ELPA `yaml` package for parsing frontmatter.

## License

GPL-3.0. See [LICENSE](LICENSE).
