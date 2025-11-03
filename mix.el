;;; mix.el --- Helper functions for working with (Elixir) Mix projects -*- lexical-binding: t -*-

;; Copyright © 2025 Jonathan Arnett <j3rn@j3rn.com>

;; Author: Jonathan Arnett <j3rn@j3rn.com>
;; URL: https://github.com/J3RN/mix.el
;; Keywords: languages, tools
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this package. If not, see https://www.gnu.org/licenses.

;;; Commentary:

;; Provides access to an IEx shell buffer, optionally running a
;; specific command (e.g. iex -S mix, iex -S mix phx.server, etc)

;;; Code:

(require 'compile)



;;; Customization

(defgroup mix nil
  "Working with Elixir Mix projects."
  :prefix "mix-"
  :group 'languages)

(defcustom mix-prefer-umbrella t
  "Whether to prefer working at the umbrella level rather than the sub-project level.

If ther is no umbrella project, the value of this variable is irrelevant."
  :type 'boolean
  :group 'inf-elixir)



;;; mix-mode definition and configuration

(defvar mix-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") #'mix-project-compile)
    (define-key map (kbd "t") #'mix-execute-task)
    (define-key map (kbd "s") #'mix-project-run-shell)
    map)
  "Keymap to be invoked post-prefix.")
(fset 'mix-command-map mix-command-map)

(defvar mix-mode-map (make-sparse-keymap)
  "An empty keymap primarily for setting the prefix.")

;;;###autoload
(define-minor-mode mix-mode
  "Minor mode to provide shortcuts to interact with Mix.

\\{mix-mode-map}"
  :keymap mix-mode-map)



;;; Utility

(defun mix--up-directory (dir)
  "Return the directory above DIR."
  (file-name-directory (directory-file-name dir)))

(defun mix--project-name (project-root)
  "Return the project name for the project located at PROJECT-ROOT."
  (file-name-base (directory-file-name project-root)))

;; Largely copied from ayrat555/mix.el.  Thank you!
(defun mix--all-available-tasks (project-root)
  "List all available mix tasks for project in PROJECT-ROOT."
  (let ((tasks (mix--fetch-all-mix-tasks project-root)))
    (mix--filter-and-format-mix-tasks tasks)))

(defun mix--fetch-all-mix-tasks (project-root)
  "Fetches list of raw mix tasks from shell for project in PROJECT-ROOT.
Use `mix--all-available-tasks` to fetch formatted and filetered tasks."
  (let* ((default-directory (or project-root default-directory))
         (tasks-string (shell-command-to-string "mix help")))
    (split-string tasks-string "\n")))

(defun mix--filter-and-format-mix-tasks (lines)
  "Filter `iex -S mix` and `mix` commands and format mix TASKS."
  (let* ((filtered-tasks
          (seq-filter
           (lambda (line)
             (and
              (string-match-p "^mix" line)
              (not (string-match-p "Runs the default task" line))))
           lines)))
    (mapcar #'mix--remove-mix-prefix-from-task filtered-tasks)))

(defun mix--remove-mix-prefix-from-task (task)
  "Remove the first `mix` word from TASK string."
  (cdr (split-string task "mix[[:blank:]]")))

(defun mix--remove-task-comment (task)
  "Remove the comment from TASK."
  (string-trim (car (string-split task "#"))))



;;; Compilation mode

(add-to-list 'compilation-error-regexp-alist-alist '(elixir "\\([^ ]+\\.\\(?:[lh]?eex\\|exs?\\)\\):\\([0-9]+\\)" 1 2))
(add-to-list 'compilation-error-regexp-alist 'elixir)

(define-derived-mode mix-compilation-mode compilation-mode "Elixir Test"
  (setq-local compilation-error-regexp-alist '(elixir)))

(defun mix-compilation--buffer-name (mode)
  "Use `MODE' to create the name for the elixir-test-output buffer."
  (concat "*" mode " " (mix--project-name default-directory) "*"))



;;; Public API

(defun mix-find-umbrella-root (start-dir)
  "Traverse upwards from START-DIR until highest mix.exs file is discovered."
  (when-let ((project-dir (locate-dominating-file start-dir "mix.exs")))
    (or (mix-find-umbrella-root (mix--up-directory project-dir))
        project-dir)))

(defun mix-find-project-root (&optional prefer-umbrella)
  "Find the root of the current Elixir project."
  (if prefer-umbrella
      (mix-find-umbrella-root default-directory)
    (locate-dominating-file default-directory "mix.exs")))



;;; Interactive commands

(defun mix-project-run-shell ()
  (interactive)
  (let ((default-directory (mix-find-project-root mix-prefer-umbrella)))
    (shell)))

(defun mix-project-compile ()
  (interactive)
  (let ((default-directory (mix-find-project-root mix-prefer-umbrella)))
    (compilation-start "mix compile"
                       #'mix-compilation-mode
                       #'mix-compilation--buffer-name)))

(defun mix-execute-task ()
  (interactive)
  (let* ((default-directory (mix-find-project-root mix-prefer-umbrella))
         (task (mix--remove-task-comment
                (completing-read "Select mix task: " (mix--all-available-tasks default-directory)))))
    (compilation-start (concat "mix " task)
                       #'mix-compilation-mode
                       #'mix-compilation--buffer-name)))


(provide 'mix)

;;; mix.el ends here
