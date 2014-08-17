(defvar mhc-process nil)

(add-to-list 'process-coding-system-alist '("^mhc$" . utf-8))

(defun mhc-process-send-command (command)
  (with-current-buffer (process-buffer mhc-process)
    (delete-region (point-min) (point-max))
    (process-send-string mhc-process (concat command "\n"))
    (let ((i 1))
      (while (not (and (> (point-max) 1)
                       (eq (char-after (1- (point-max))) ?\n)))
        (message (format "Waiting mhc process...%d" i))
        (setq i (1+ i))
        (accept-process-output mhc-process 0.5)))
      (read (buffer-substring (point-min) (1- (point-max))))))

(defun mhc-start-process ()
  (interactive)
  (let ((base-dir (mhc-summary-folder-to-path mhc-base-folder)))
    (if (and (processp mhc-process)
             (eq (process-status mhc-process) 'run))
        (kill-process mhc-process))
    (setq mhc-process (start-process
                       "mhc"
                       (get-buffer-create " *mhc-scan-process*")
                       "mhc"
                       "server"
                       (format "--repository=%s" base-dir)))
    (set-process-query-on-exit-flag mhc-process nil)
    mhc-process))

(provide 'mhc-process)
