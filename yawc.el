;;; yawc.el --- Yet Another Word Counter -*- lexical-binding: t -*-

;; Copyright (C) 2022 Bruno Cardoso

;; Author: Bruno Cardoso <cardoso.bc@gmail.com>
;; URL: https://github.com/bcardoso/yawc
;; Version: 0.1
;; Package-Requires: ((emacs "27.2"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Yet another word counter minor-mode for achieving writing goals.

;;; Code:

(defgroup yawc nil
  "Group for `yawc-mode' customizations."
  :group 'yawc)

(defcustom yawc-writing-goal-default 500
  "Default writing goal."
  :group 'yawc
  :type 'integer)

(defcustom yawc-idle-interval 10
  "Idle interval, in seconds, to count the words."
  :group 'yawc
  :type 'integer)

(defcustom yawc-lighter " yawc"
  "Lighter to be displayed in the mode line when the mode is on."
  :group 'yawc
  :type 'string)

(defvar yawc-current-buffer nil
  "Count words from this buffer.")

(defvar yawc-initial-word-count nil
  "Initial word count.")

(defvar yawc-writing-goal nil
  "Writing goal.")

(defun yawc--init ()
  "Initialize yawc-mode variables for the current buffer."
  (setq-local yawc-current-buffer (current-buffer)
              yawc-initial-word-count (count-words (point-min) (point-max))
              yawc-writing-goal (string-to-number
                             (read-from-minibuffer
                              (format "Word goal [Default: %s]: "
                                      yawc-writing-goal-default))))
  (if (or (eq yawc-writing-goal nil) (<= yawc-writing-goal 0))
      (setq-local yawc-writing-goal yawc-writing-goal-default))
  (message (format "Your writing goal is %s words." yawc-writing-goal)))

(defun yawc--status ()
  "Current word count status."
  (when (equal (current-buffer) yawc-current-buffer)
    (let ((current-word-count (count-words (point-min) (point-max)))
          (word-goal-total (+ yawc-initial-word-count yawc-writing-goal)))
      (if (>= current-word-count word-goal-total)
          (message (format "Alright! You wrote %s words."
                           (- current-word-count yawc-initial-word-count)))
        (message (format "Keep going... %s words remaining."
                         (- word-goal-total current-word-count)))))))

;;;###autoload
(define-minor-mode yawc-mode
  "Enable yawc-mode in current buffer."
  :init-value nil
  :lighter yawc-lighter
  (if yawc-mode
      (progn
        (if (not yawc-current-buffer)
            (yawc--init))
        (run-with-idle-timer yawc-idle-interval t #'yawc--status))
    (cancel-function-timers #'yawc--status)
    (setq-local yawc-current-buffer nil)
    (let ((current-word-count (count-words (point-min) (point-max))))
      (message
       (format "You wrote %s words, your goal was %s. Buffer now has %s words."
               (- current-word-count yawc-initial-word-count)
               yawc-writing-goal
               current-word-count)))))

(provide 'yawc)

;;; yawc.el ends here
