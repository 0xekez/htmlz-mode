# htmlz-mode

![a demo of me using htmlz mode](demo.gif)

```
M-x htmlz-mode
```

This is a small, dead-simple, Emacs minor mode that shows a live
preview of a html document as you work on it. This is inspired by the
live preview option for the Brackets text editor.

## Usage

Download the emacs lisp file and move it somewhere that your Emacs
will see and evaluate it on startup. Then, run `M-x htmlz-mode` while
editing an html file to open a live preview in your default browser.

## Why

I made this because I occasionally find myself in the position of
editing some html and wanting to see a simple live preview of it as I
work. If you do this sort of thing seriously, I'd imagine that there
are much better ways to manage this, but as a non web developer who
occasionally needs to write some html I've found this to be quite
pleasant.

## How it works

This is my first Emacs Lisp program ever so it's likely to be less
than ideal in many ways. I'd love feedback.

In a nutshell, htmlz-mode works like this:

1. Create a temporary html file.
2. Start a websocket server in Emacs.
3. Place some Javascript in that file that opens a websocket
   connection with Emacs.
4. Open the temporary file in the default browser.
5. When the buffer contents change send the new buffer contents over
   the websocket connection from Emacs.
6. When a new websocket message is received in the browser, update the
   page contents with that message.
