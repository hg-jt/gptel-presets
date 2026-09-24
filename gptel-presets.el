;;; gptel-presets.el --- Define gptel presets from Markdown files -*- lexical-binding: t; -*-

;; Copyright (C) 2026 hg-jt
;; Author: hg-jt <hg-jt@users.noreply.github.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "31.1") (gptel "0.9.9.5") (yaml "1.2.1"))
;; Keywords: convenience, outlines, tools
;; URL: https://github.com/hg-jt/gptel-presets

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package loads gptel presets from Markdown files with YAML
;; front matter. For example, `coding.md' becomes the `coding' preset,
;; with the YAML properties converted to gptel keyword arguments and
;; the Markdown body used as the `:system' prompt.

;;; Code:

(require 'cl-lib)
(require 'gptel)
(require 'subr-x)
(require 'yaml)

(defgroup gptel-presets nil
  "Manage gptel presets stored in Markdown files."
  :group 'gptel
  :prefix "gptel-presets-")

(defcustom gptel-presets-directory
  (expand-file-name "gptel-presets" user-emacs-directory)
  "Directory containing Markdown files that define gptel presets."
  :type 'directory
  :group 'gptel-presets)

(defun gptel-presets--key (key)
  "Return KEY as a symbol suitable for a gptel keyword argument."
  (intern (concat ":" (if (symbolp key) (symbol-name key) key))))

(defun gptel-presets--value (key value)
  "Normalize VALUE for the YAML field KEY."
  (cond
   ((eq key :model)
    (if (stringp value) (intern value) value))
   ((eq key :parents)
    (mapcar (lambda (parent)
              (if (stringp parent) (intern parent) parent))
            value))
   (t value)))

(defun gptel-presets--yaml-to-plist (yaml)
  "Convert parsed YAML alist YAML to a gptel preset plist."
  (cl-loop for (key . value) in yaml
           for keyword = (gptel-presets--key key)
           append (list keyword (gptel-presets--value keyword value))))

(defun gptel-presets--parse-file (file)
  "Return the preset name and plist described by FILE.

The returned value is a cons whose car is the preset symbol and whose cdr is
the plist passed to `gptel-make-preset'."
  (let ((contents (with-temp-buffer
                    (insert-file-contents file)
                    (string-replace "\r\n" "\n" (buffer-string)))))
    (unless (string-match (rx string-start "---" (* blank) "\n")
                          contents)
      (user-error "File does not contain YAML frontmatter: %s" file))
    (let* ((yaml-start (match-end 0))
           (yaml-end (and (string-match
                           (rx "\n" "---" (* blank)
                               (or "\n" string-end))
                           contents yaml-start)
                          (match-beginning 0)))
           (body-start (and yaml-end (match-end 0)))
           (yaml-text (and yaml-end (substring contents yaml-start yaml-end)))
           (body (and body-start (substring contents body-start))))
      (unless yaml-end
        (user-error "YAML frontmatter is not closed: %s" file))
      (let* ((yaml (yaml-parse-string yaml-text
                                      :object-type 'alist
                                      :sequence-type 'list))
             (name (intern (file-name-base file)))
             (plist (gptel-presets--yaml-to-plist yaml)))
        (cons name (append plist (list :system (string-trim body))))))))

;;;###autoload
(defun gptel-presets-load-file (file)
  "Load the gptel preset defined by FILE.

FILE must be a Markdown file whose frontmatter is valid YAML.  Loading a file
again updates the preset through `gptel-make-preset'."
  (interactive (list (read-file-name "Preset file: "
                                     gptel-presets-directory nil t nil
                                     "\\.md\\'")))
  (pcase-let ((`(,name . ,plist) (gptel-presets--parse-file file)))
    (apply #'gptel-make-preset name plist)
    name))

;;;###autoload
(defun gptel-presets-load-directory (&optional directory)
  "Load every Markdown preset in DIRECTORY.

When DIRECTORY is nil, use `gptel-presets-directory'.  Files are loaded in
lexicographic order.  Return a list of the loaded preset names."
  (interactive)
  (let* ((directory (file-name-as-directory
                     (or directory gptel-presets-directory)))
         (files (and (file-directory-p directory)
                     (directory-files directory t "\\.md\\'" t)))
         (names (mapcar #'gptel-presets-load-file (sort files #'string<))))
    (when (called-interactively-p 'interactive)
      (message "Loaded %d gptel preset%s from %s"
               (length names) (if (= 1 (length names)) "" "s") directory))
    names))

;;;###autoload
(defun gptel-presets-load-default-directory ()
  "Load presets from `gptel-presets-directory' if it exists."
  (interactive)
  (when (file-directory-p gptel-presets-directory)
    (gptel-presets-load-directory gptel-presets-directory)))

(provide 'gptel-presets)

;;; gptel-presets.el ends here
