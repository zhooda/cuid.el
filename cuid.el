;;; cuid.el --- Generate collision resistent cuid2 ids -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Zeeshan Hooda
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


;; Author: Zeeshan Hooda <zee@sparselabs.org>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: wp tools files convenience data
;; URL: https://github.com/gongo/airplay-el


;;; Commentary:

;; An implementation of cuid2 in Emacs Lisp based on:
;;   reference implementation: https://github.com/paralleldrive/cuid2
;;   python implementation:    https://github.com/gordon-code/cuid2
;;
;; This library is not meant for real world usage, rather to simply to
;; generate cuids while editing text. As such, the collision resistance
;; of cuids generated with this library should not be trusted.
;;
;; NOTE: The default Emacs SHA512 algorithm is used here, which is NOT
;; the latest SHA-3 version as used in the cuid2 reference implementation.
;; This library follows the logic from the Python implementation which
;; falls back to SHA-2 512 if the SHA-3 version is not available, only
;; in this case always using the SHA-2 version.

;;; Code:

(provide 'cuid)

(require 'calc-bin)

(defvar cuid/big-length 32)
(defvar cuid/initial-count-max 476782367)
(defvar cuid/default-length 24)
(defvar cuid/maximum-length 98)
(defvar cuid/default-fingerprint)


(defun cuid/create-counter (count)
  "Returns a counter function from an initial count value."
  (let ((c (1- count)))
    (lambda ()
      (setq c (1+ c))
      c)))

(defun cuid/random-float ()
  "Generates a random float between 0 and 1 using the systems entropy pool."
  (/ (- (float (random t))
        most-negative-fixnum)
     (- most-positive-fixnum most-negative-fixnum)))

(defun cuid/create-letter ()
  "Generates a random lowercase letter."
  (let* ((alpha "abcdefghijklmnopqrstuvwxyz")
         (i (% (abs (random t)) (length alpha))))
    (substring alpha i (1+ i))))

(defun cuid/env-var-names ()
  "Returns a list of environment variable names without their values."
  (let ((names ""))
    (dolist (pair process-environment names)
      (let ((name (car (split-string pair "="))))
        (setq names (concat names name))))
    names))

(defun cuid/base36-encode (number)
  "Encodes a positive integer into a base36 string."
  (downcase
   (let ((calc-number-radix 36))
     (math-format-radix number))))

(defun cuid/create-hash (string)
  "Creates a hash of the input string using SHA512 and returns the base36 encoded integer without the first character."
  (let* ((digest (secure-hash 'sha512 string nil nil))
         (digest-int (string-to-number digest 16))
         (digest-encoded (cuid/base36-encode digest-int)))
    (substring digest-encoded 1)))

(defun cuid/create-entropy (&optional len)
  "Creates a random string of specified length using a base36 encoding."
  (unless len (setq len 4))
  (if (< len 1)
      (error "Cannot create entropy without a length >= 1")
    (let ((entropy ""))
      (while (< (length entropy) len)
        (setq entropy (concat entropy
                              (cuid/base36-encode
                               (floor (* (cuid/random-float) 36))))))
      entropy)))

(defun cuid/create-fingerprint (&optional data)
  "Creates a fingerprint, by default combining the pid, hostname, and environment variable names with entropy, then hashing the result."
  (unless data (setq data (concat
                           (number-to-string (emacs-pid))
                           (system-name)
                           (cuid/env-var-names))))
  (substring
   (cuid/create-hash (concat data (cuid/create-entropy cuid/big-length)))
   0 cuid/big-length))

(setq cuid/default-fingerprint (cuid/create-fingerprint))

(defun cuid/generate (&optional counter len fingerprint)
  "Generates a universally unique base36 encoded string with a specified length."
  (unless counter
    (setq counter
          (cuid/create-counter
           (floor (* (cuid/random-float) cuid/initial-count-max)))))
  (unless len (setq len cuid/default-length))
  (unless fingerprint (setq fingerprint cuid/default-fingerprint))
  (if (> len cuid/maximum-length)
      (error "Length must never exceed 98 characters."))
  (let* ((first-letter (cuid/create-letter))
         (time-base36 (cuid/base36-encode (car (time-convert nil 1000000000))))
         (count-base36 (cuid/base36-encode (funcall counter)))
         (salt (cuid/create-entropy len))
         (hash-input (concat time-base36 salt count-base36 fingerprint)))
    (concat first-letter (substring (cuid/create-hash hash-input) 1 len))))

(defun cuid/replace-region ()
  "Replace the selected region with a newly generated cuid."
  (interactive)
  (when (region-active-p)
    (delete-region (region-beginning) (region-end))
    (insert (cuid/generate))))

(defun cuid/insert ()
  "Insert a newly generated cuid into the buffer."
  (interactive)
  (insert (cuid/generate)))

;;; cuid.el ends here
