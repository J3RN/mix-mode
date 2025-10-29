# mix.el

An [Emacs] package for working with [Mix] projects.

## Installation

Currently, the project is not yet on a package archive, but you can install it via `use-package` with the `:vc` option if you are using Emacs version 30 or newer:

```
(use-package mix
  :vc (:url "https://github.com/J3RN/mix.el"
       :rev :newest)))
```

[Emacs]: https://www.gnu.org/software/emacs/
[Mix]: https://hexdocs.pm/mix/1.12/Mix.html
