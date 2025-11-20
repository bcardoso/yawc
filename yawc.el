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

;;;; User options

(defgroup yawc nil
  "Group for `yawc-mode' customizations."
  :group 'yawc)

(defcustom yawc-writing-goal-default 500
  "Default writing goal."
  :type 'natnum)

(defcustom yawc-lighter " YAWC"
  "Lighter to be displayed in the mode line when the `yawc-mode' is enabled."
  :type 'string)

(defcustom yawc-show-status-when-idle t
  "When non-nil, show current report status in echo area."
  :type 'boolean)

(defcustom yawc-status-idle-interval 5
  "Idle interval, in seconds, to show current word count in echo area."
  :type 'natnum)

(defcustom yawc-show-mode-line-indicator t
  "When non-nil, show the word count indicator in the mode line."
  :type 'boolean)

(defface yawc-indicator-goal-reached
  '((t (:inherit success :weight bold)))
  "Mode line face for when the word count goal is reached.")

(defface yawc-indicator-goal-unreached
  '((t (:inherit mode-line-active)))
  "Mode line face for when the word count goal is still unreached.")


;;;; Word counting

(defvar-local yawc-initial-word-count 0
  "Initial word count.")

(defvar-local yawc-writing-goal nil
  "Current writing goal.")

(defun yawc-set-word-goal ()
  "Set word count goal for the current buffer."
  (let ((goal (read-number "Word goal: " yawc-writing-goal-default)))
    (setq-local yawc-writing-goal (if (<= goal 0)
                                      yawc-writing-goal-default
                                    goal))))

(defun yawc--total ()
  "Total number of words in current buffer."
  (count-words (point-min) (point-max)))

(defun yawc--current ()
  "Number of words written in current buffer."
  (- (yawc--total) yawc-initial-word-count))

(defun yawc--target ()
  "Total number of words in current buffer to reach goal."
  (+ yawc-initial-word-count yawc-writing-goal))

(defun yawc--remaining ()
  "Number of remaining words to reach goal."
  (- (+ yawc-initial-word-count yawc-writing-goal) (yawc--total)))

(defun yawc--goal-reached-p ()
  "Return t if word count goal was reached."
  (>= (yawc--total) (yawc--target)))


;;;; Helper

(defvar yawc-mode)

(defvar-local yawc-indicator-buffer-modified nil)

(defmacro yawc-with-buffer-modified (&rest body)
  "Run BODY when in `yawc-mode' and buffer has been modified."
  `(when (and yawc-mode (not (eq yawc-indicator-buffer-modified
                                 (buffer-modified-tick))))
     (setq-local yawc-indicator-buffer-modified (buffer-modified-tick))
     ,@body))


;;;; Live status

(defvar-local yawc-status-timer nil
  "Timer for `yawc--status'.")

(defun yawc--goal-reached-message ()
  "Message for when the word count goal is reached."
  (format "Alright! You wrote %d words. Your goal was %d."
          (yawc--current) yawc-writing-goal))

(defun yawc--goal-unreached-message ()
  "Message for when the word count goal is still unreached."
  (format "Keep going... %s words remaining." (yawc--remaining)))

(defun yawc--status ()
  "Current word count status."
  (yawc-with-buffer-modified
   (message (if (yawc--goal-reached-p)
                (yawc--goal-reached-message)
              (yawc--goal-unreached-message)))))


;;;; Mode line indicator

(defvar-local yawc-indicator-timer nil
  "Timer for `yawc--indicator'.")

(defvar-local yawc-indicator-string nil)
(defvar-local yawc-indicator '(yawc-mode (" " :eval yawc-indicator-string)))
(put 'yawc-indicator 'risky-local-variable t)
(put 'yawc-indicator-string 'risky-local-variable t)

(defun yawc--indicator-status ()
  "Show word count status."
  (concat (format "Current: %d words\n" (yawc--current))
          (format "Goal: %d words\n" yawc-writing-goal)
          (format "Remaining: %d words\n" (yawc--remaining))
          (format "Initial count: %d\n" yawc-initial-word-count)
          (format "Total in buffer: %d" (yawc--total))))

(defun yawc--indicator ()
  "Display current word count in the mode line."
  (let* ((current (yawc--current)))
    (propertize
     (format " [WC: %s] "
             (propertize
              (format "%s/%s" current yawc-writing-goal)
              'face (if (yawc--goal-reached-p)
                        'yawc-indicator-goal-reached
                      'yawc-indicator-goal-unreached)))
     'mouse-face 'mode-line-highlight
     'help-echo (yawc--indicator-status))))

(defun yawc--indicator-update ()
  "Update mode line indicator."
  (yawc-with-buffer-modified
   (setq-local yawc-indicator-string (yawc--indicator))))


;;;; YAWC mode

(defun yawc-init ()
  "Initialize `yawc-mode' for the current buffer."
  (yawc-set-word-goal)
  (setq-local yawc-initial-word-count (yawc--total)
              yawc-indicator-buffer-modified nil)
  (message (format "Your writing goal is %s words." yawc-writing-goal)))

(defun yawc-report ()
  "Report current status."
  (message
   (format "You wrote %s words, your goal was %s. Buffer now has %s words."
           (yawc--current) yawc-writing-goal (yawc--total))))

(defun yawc-reset ()
  "Redefine word count goals for the current buffer."
  (interactive)
  (yawc-init))

(defun yawc-mode--enable ()
  "Init `yawc-mode' in current buffer and enable timers."
  (yawc-init)
  (when yawc-show-status-when-idle
    (setq-local yawc-status-timer
                (run-with-idle-timer yawc-status-idle-interval t
                                     #'yawc--status)))
  (when yawc-show-mode-line-indicator
    (setq-local yawc-indicator-timer
                (run-with-idle-timer 0.5 t #'yawc--indicator-update))
    (add-hook 'mode-line-misc-info yawc-indicator nil :local))
  (add-hook 'kill-buffer-hook #'yawc-mode--disable nil :local))

(defun yawc-mode--disable ()
  "Disable `yawc-mode' in current buffer."
  (and yawc-indicator-timer (cancel-timer yawc-indicator-timer))
  (and yawc-status-timer (cancel-timer yawc-status-timer))
  (remove-hook 'mode-line-misc-info yawc-indicator :local)
  (force-mode-line-update t)
  (yawc-report))

;;;###autoload
(define-minor-mode yawc-mode
  "Enable `yawc-mode' in current buffer."
  :init-value nil
  :lighter yawc-lighter
  (if yawc-mode
      (yawc-mode--enable)
    (yawc-mode--disable)))


;;; Provide

(provide 'yawc)

;;; yawc.el ends here
