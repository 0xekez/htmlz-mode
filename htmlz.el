;; htmlz-mode
;;
;; An Emacs mode that gives a live preview while you edit html. There
;; are other programs that do this and they are reasonably good I'm
;; sure, but they all seem a little more complicated than I'd actually
;; like. This doesn't have any shortcuts or really add anything other
;; than a live preview that starts if you run M-x htmlz-mode from a
;; buffer.

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
  "The current websocket server. Created after the client opens a
  websocket connection with us.")

(defun htmlz-get-current-extension ()
  (car (reverse (split-string (buffer-file-name) "\\."))))

(defun htmlz-get-current-dir ()
  (file-name-directory (buffer-file-name)))

(defun htmlz-get-filename ()
  (concat (htmlz-get-current-dir) "~htmlz-tmp." (htmlz-get-current-extension)))

(defun htmlz-init-file ()
  "Creates a file which htmlz loads. The file contains javascript
which can communicate with our websockets server."
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
  (browse-url (htmlz-get-filename)))

(defun htmlz-init-server ()
  (interactive)
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
  (htmlz-init-dependencies)
  (htmlz-init-file)
  (htmlz-init-server)
  (htmlz-open-file)
  (add-hook 'post-command-hook 'htmlz-send-buffer-contents nil 'local))

(defun htmlz-finish ()
  (htmlz-close-server)
  (delete-file (htmlz-get-filename))
  (remove-hook 'post-command-hook 'htmlz-send-buffer-contents 'local))

(define-minor-mode htmlz-mode
  "Get your foos in the right places."
  :lighter " htmlz"
  ; This is executed after the macro has toggled the mode. This means
  ; that the mode not being on implies that it has been turned off and
  ; the mode being on implies that it has been turned on.
  (if (not htmlz-mode)
      (htmlz-finish)
    (htmlz-start)))

(provide 'htmlz-mode)
