# mix.el

An [Emacs] package for working with [Mix] projects.

## Installation

Currently, the project is not yet on a package archive, but you can install it via `use-package` with the `:vc` option if you are using Emacs version 30 or newer:

```
(use-package mix
  :vc (:url "https://github.com/J3RN/mix.el"
       :rev :newest)))
```

If you use `project.el` and want to have `project.el` detect projects by the presence of a `mix.exs` file, use the following config:

```
(use-package mix
  :vc (:url "https://github.com/J3RN/mix.el"
       :rev :newest)))
  :config
  (add-to-list 'project-find-functions 'mix-project-find-root)
```

[Emacs]: https://www.gnu.org/software/emacs/
[Mix]: https://hexdocs.pm/mix/1.12/Mix.html
