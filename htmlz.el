;;; htmlz --- Simple real-time Emacs html preview

;; Copyright (C) 2020 Zeke Medley

;; Author: Zeke Medley <zekemedley@gmail.com>
;; Keywords: html
;; Version: 0.1
;; URL: https://github.com/ZekeMedley/htmlz

;;; Commentary:
;; htmlz-mode is an Emacs mode that gives a live preview while you
;; edit html.  There are other programs that do this and they are
;; reasonably good I'm sure, but they all seem a little more
;; complicated than I'd actually like.  This doesn't have any
;; shortcuts or really add anything other than a live preview that
;; starts if you run M-x htmlz-mode from a buffer.

;;
;;; Code:

(defun require-package (package)
  "Install given PACKAGE if it was not installed before."
  (if (package-installed-p package)
      t
    (progn
      (unless (assoc package package-archive-contents)
	(package-refresh-contents))
      (package-install package))))

(defun htmlz-init-dependencies ()
  "Initialize htmlz dependencies."
  (require-package 'websocket)
  (require 'package)
  (require 'browse-url)
  (require 'websocket))

(defvar htmlz-opened-websocket nil
  "The currently open websocket.")
(defvar htmlz-the-server nil
  "The current websocket server.  Created after the client opens a websocket connection with us.")

(defun htmlz-get-current-extension ()
  "Gets the file extension for the current buffer."
  (car (reverse (split-string (buffer-file-name) "\\."))))

(defun htmlz-get-current-dir ()
  "Gets the directory for the current buffer."
  (file-name-directory (buffer-file-name)))

(defun htmlz-get-filename ()
  "Gets the filename for the current buffer."
  (concat (htmlz-get-current-dir) "~htmlz-tmp." (htmlz-get-current-extension)))

(defun htmlz-init-file ()
  "Create a file for htmlz to load."
  (write-region "<!DOCTYPE html>
<script>
const ws = new WebSocket('ws://localhost:3000')
ws.onmessage = function(event) {
// This method, while more pendatic, is much slower.
// document.open()
// document.write(event.data)
// document.close()
document.body.innerHTML = event.data;
}
</script>"
		nil (htmlz-get-filename)
		nil 'quiet))

(defun htmlz-open-file ()
  "Opens the htmlz file in the default browser."
  (browse-url (htmlz-get-filename)))

(defun htmlz-init-server ()
  "Initialize the htmlz websocket server."
  (if htmlz-the-server
      (htmlz-close-server))
  (setq htmlz-the-server
  	(websocket-server
  	 3000
  	 :host 'local
  	 :on-open (lambda (ws) (setq htmlz-opened-websocket ws))
	 :on-close (lambda (ws) (setq htmlz-opened-websocket nil)))))

(defun htmlz-send-buffer-contents ()
  "Sends the contents of the current buffer to the browser."
  (if htmlz-opened-websocket
      (websocket-send-text htmlz-opened-websocket (buffer-string))
    (message "error: no open websocket connection")))

(defun htmlz-close-server ()
  "Closes our websocket server."
  (websocket-server-close htmlz-the-server))

(defun htmlz-start ()
  "Startup htmlz."
  (htmlz-init-dependencies)
  (htmlz-init-file)
  (htmlz-init-server)
  (htmlz-open-file)
  (add-hook 'post-command-hook 'htmlz-send-buffer-contents nil 'local))

(defun htmlz-finish ()
  "Clean up htmlz."
  (htmlz-close-server)
  (delete-file (htmlz-get-filename))
  (remove-hook 'post-command-hook 'htmlz-send-buffer-contents 'local))

(define-minor-mode htmlz-mode
  "The htmlz minor mode"
  :lighter " htmlz"
  ; This is executed after the macro has toggled the mode. This means
  ; that the mode not being on implies that it has been turned off and
  ; the mode being on implies that it has been turned on.
  (if (not htmlz-mode)
      (htmlz-finish)
    (htmlz-start)))

(provide 'htmlz-mode)
;;; htmlz.el ends here
