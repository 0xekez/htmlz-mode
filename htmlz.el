;; Things to think about:
;;
;;  1. This currently does not render images correctly as the base
;;     directoy changes for the html file. Stylesheets are the same
;;     deal. This is clearly no good.
;;  2. Currently our script tag that we insert injects html in to the
;;     document body, but does not replace the html on the page as
;;     this would likely cause it to replace itself. I am not sure
;;     that it replacing itself is actually a problem though as long
;;     as it runs once and sets up the websocket.
;;
;; Likely to solve these problems we will have to create a temporary
;; file in the same directory as the buffer's file and then load the
;; buffer contents in.

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

(defun htmlz-init-file ()
  "Creates a file which htmlz loads. The file contains javascript
which can communicate with our websockets server."
  (write-region "<!DOCTYPE html>
<script>
const ws = new WebSocket('ws://localhost:3000')
ws.onmessage = function(event) {
document.body.innerHTML = event.data;
}
</script>"
		nil "/tmp/.emacs-http-server.html"
		nil 'quiet))
(defun htmlz-open-file ()
  (browse-url "/tmp/.emacs-http-server.html"))

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
