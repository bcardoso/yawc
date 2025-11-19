;;; yawc.el --- Yet Another Word Counter -*- lexical-binding: t -*-

;; Copyright (C) 2022-2025 Bruno Cardoso

;; Author: Bruno Cardoso <cardoso.bc@gmail.com>
;; URL: https://github.com/bcardoso/yawc
;; Version: 0.2
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
  :type 'natnum)

(defcustom yawc-idle-interval 10
  "Idle interval, in seconds, to show current word count in echo area."
  :type 'natnum)

(defcustom yawc-lighter " YAWC"
  "Lighter to be displayed in the mode line when the mode is on."
  :type 'string)

(defvar-local yawc-initial-word-count 0
  "Initial word count.")

(defvar-local yawc-writing-goal nil
  "Writing goal.")

(defun yawc--read-word-goal ()
  "Read word count goal."
  (let ((goal (read-number "Word goal: " yawc-writing-goal-default)))
    (if (<= goal 0)
        yawc-writing-goal-default
      goal)))

(defun yawc--total ()
  "Number of words in current buffer."
  (count-words (point-min) (point-max)))

(defun yawc--current ()
  "Number of words written in current buffer."
  (- (yawc--total) yawc-initial-word-count))

(defun yawc--target ()
  "Number of words to reach from inicial word count."
  (+ yawc-initial-word-count yawc-writing-goal))

(defun yawc--remaining ()
  "Number of remaining words to reach goal."
  (- (+ yawc-initial-word-count yawc-writing-goal) (yawc--total)))

(defun yawc--init ()
  "Initialize yawc-mode for the current buffer."
  (setq-local yawc-initial-word-count (yawc--total)
              yawc-writing-goal (yawc--read-word-goal))
  (message (format "Your writing goal is %s words." yawc-writing-goal)))

(defun yawc--status ()
  "Current word count status."
  (when yawc-mode
    (message
     (if (>= (yawc--total) (yawc--target))
         (format "Alright! You wrote %d words. Your goal was %d."
                 (yawc--current) yawc-writing-goal)
       (format "Keep going... %s words remaining." (yawc--remaining))))))

(defun yawc--report ()
  "Report current status."
  (message
   (format "You wrote %s words, your goal was %s. Buffer now has %s words."
           (yawc--current) yawc-writing-goal (yawc--total))))

(defun yawc-reset ()
  "Redefine word count goals for the current buffer."
  (interactive)
  (yawc--init))

;;;###autoload
(define-minor-mode yawc-mode
  "Enable yawc-mode in current buffer."
  :init-value nil
  :lighter yawc-lighter
  (if yawc-mode
      (progn
        (yawc--init)
        (run-with-idle-timer yawc-idle-interval t #'yawc--status))
    (cancel-function-timers #'yawc--status)
    (yawc--report)))


;;; Provide

(provide 'yawc)

;;; yawc.el ends here
