#!/usr/bin/env python3
import json
import os
import select
import socket
import subprocess
import sys


EVENTS = (
    b"workspace", b"createworkspace", b"destroyworkspace", b"movewindow",
    b"openwindow", b"closewindow", b"focusedmon",
)


def query(command):
    result = subprocess.run(
        ["hyprctl", command, "-j"], capture_output=True, text=True,
        timeout=2, check=True,
    )
    return json.loads(result.stdout)


def emit(workspace):
    try:
        active = query("activeworkspace").get("id")
        windows = sum(
            item.get("windows", 0) for item in query("workspaces")
            if item.get("id") == workspace
        )
    except (OSError, ValueError, subprocess.SubprocessError):
        return
    state = "active" if active == workspace else "occupied" if windows else "empty"
    payload = {
        "text": f"{workspace:02d}",
        "class": state,
        "tooltip": f"Workspace {workspace} · {windows} windows",
    }
    os.write(1, (json.dumps(payload, ensure_ascii=False) + "\n").encode())


def main():
    if len(sys.argv) != 2:
        return 2
    try:
        workspace = int(sys.argv[1])
        path = os.path.join(
            os.environ["XDG_RUNTIME_DIR"], "hypr",
            os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock",
        )
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as events:
            events.connect(path)
            poller = select.poll()
            poller.register(events, select.POLLIN | select.POLLHUP | select.POLLERR)
            poller.register(1, select.POLLERR | select.POLLHUP | select.POLLNVAL)
            emit(workspace)
            pending = b""
            while True:
                ready = poller.poll()
                if any(fd == 1 for fd, _ in ready):
                    return 0
                for fd, _ in ready:
                    if fd != events.fileno():
                        continue
                    chunk = events.recv(65536)
                    if not chunk:
                        return 0
                    pending += chunk
                    lines = pending.split(b"\n")
                    pending = lines.pop()
                    if any(line.startswith(EVENTS) for line in lines):
                        emit(workspace)
    except BrokenPipeError:
        return 0
    except (KeyError, ValueError, OSError):
        return 1


if __name__ == "__main__":
    sys.exit(main())
