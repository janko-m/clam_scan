# HEAD

### Allow `stream` to be an IO object

In addition to passing `stream` as a String, now you can also pass in any IO
object, which will be streamed to the standard input. This is suitable for
larger files, where we want to avoid having to load the whole file into
memory.

# 0.0.2

### Add `fdpass` to validated options

Pass the file descriptor permissions to `clamd`. This is useful if `clamd` is running as a different user as it is faster than streaming the file to `clamd`. Only available if connected to `clamd` via local(unix) socket.

Or, in human language: `--fdpass` is needed if user `clamav`, as which `clamd` runs, cannot access your files. Which may be the case with e.g. rails and scanning temporary uploads.

# 0.0.1

### Initial release

It's alive!
