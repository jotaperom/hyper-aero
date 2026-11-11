import json
import os
from pathlib import Path
import queue
import select
import signal
import socket
import subprocess
import tempfile
import threading
import time
import unittest

HELPER = Path(os.environ.get('WSPILL_HELPER', Path(__file__).resolve().parents[2] /
              'dotfiles/.config/hyper-aero/scripts/ws-pill.sh'))


class WorkspacePillTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='pill-')
        self.root = Path(self.temp.name)
        self.state = self.root / 'state.json'
        self.set_state(1, 2)
        command = self.root / 'hyprctl'
        command.write_text(
            '#!/usr/bin/env python3\nimport json,os,sys\n'
            "s=json.load(open(os.environ['PILL_STATE']))\n"
            "print(json.dumps(s['activeworkspace' if 'activeworkspace' in sys.argv else 'workspaces']))\n")
        command.chmod(0o755)
        runtime = self.root / 'hypr/test'
        runtime.mkdir(parents=True)
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(str(runtime / '.socket2.sock'))
        self.server.listen()
        self.server.settimeout(.1)
        self.connections = queue.Queue()
        self.done = threading.Event()
        self.env = dict(os.environ, PATH=str(self.root) + os.pathsep + os.environ['PATH'],
                        XDG_RUNTIME_DIR=str(self.root), HYPRLAND_INSTANCE_SIGNATURE='test',
                        PILL_STATE=str(self.state))
        self.children, self.groups, self.sockets = [], [], []
        def accept():
            while not self.done.is_set():
                try:
                    conn, _ = self.server.accept()
                    self.connections.put(conn)
                except socket.timeout:
                    continue
                except OSError:
                    return
        self.thread = threading.Thread(target=accept)
        self.thread.start()

    def tearDown(self):
        self.done.set()
        self.server.close()
        self.thread.join(timeout=1)
        for group in self.groups:
            try:
                os.killpg(group, signal.SIGKILL)
            except ProcessLookupError:
                pass
        for child in self.children:
            if child.poll() is None:
                child.kill()
            child.wait(timeout=3)
            for stream in (child.stdout, child.stderr):
                if stream:
                    stream.close()
        for conn in self.sockets:
            conn.close()
        while not self.connections.empty():
            self.connections.get_nowait().close()
        self.temp.cleanup()

    def set_state(self, active, windows):
        self.state.write_text(json.dumps({'activeworkspace': {'id': active},
                                         'workspaces': [{'id': 1, 'windows': windows}]}))

    def connection(self):
        conn = self.connections.get(timeout=4)
        self.sockets.append(conn)
        return conn

    def launch(self):
        child = subprocess.Popen(['bash', str(HELPER), '1'], env=self.env,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 start_new_session=True)
        self.children.append(child)
        self.groups.append(child.pid)
        return child, self.connection()

    def read(self, child):
        self.assertTrue(select.select([child.stdout], [], [], 4)[0], 'No pill update')
        return json.loads(child.stdout.readline())

    def test_active_occupied_empty_and_split_events(self):
        child, conn = self.launch()
        self.assertEqual(self.read(child), {'text': '01', 'class': 'active',
                                          'tooltip': 'Workspace 1 · 2 windows'})
        self.set_state(2, 3)
        conn.sendall(b'activewindow>>ignored\n')
        self.assertFalse(select.select([child.stdout], [], [], .1)[0])
        conn.sendall(b'work')
        self.assertFalse(select.select([child.stdout], [], [], .1)[0])
        conn.sendall(b'space>>2\n')
        self.assertEqual(self.read(child)['class'], 'occupied')
        self.set_state(2, 0)
        conn.sendall(b'closewindow>>abc\n')
        self.assertEqual(self.read(child)['class'], 'empty')

    def test_exits_when_waybar_closes_pipe_without_workspace_events(self):
        child, conn = self.launch()
        self.read(child)
        child.stdout.close()
        self.assertEqual(child.wait(timeout=2), 0)
        conn.settimeout(2)
        self.assertEqual(conn.recv(1), b'')

    def test_exits_when_compositor_disconnects(self):
        child, conn = self.launch()
        self.read(child)
        conn.shutdown(socket.SHUT_RDWR)
        self.assertEqual(child.wait(timeout=2), 0)

    def test_repeated_panel_death_does_not_leave_helpers(self):
        owner_code = (
            'import json,subprocess,sys,signal\n'
            "children=[subprocess.Popen(['bash',sys.argv[1],str(i)],stdout=subprocess.PIPE,"
            'stderr=subprocess.DEVNULL,start_new_session=True) for i in range(1,4)]\n'
            'for p in children: p.stdout.readline()\n'
            "open(sys.argv[2],'w').write(json.dumps([p.pid for p in children]))\n"
            'signal.pause()\n')
        for cycle in range(3):
            ready = self.root / f'owner-{cycle}.json'
            owner = subprocess.Popen(['python3', '-c', owner_code, str(HELPER), str(ready)],
                                     env=self.env, stdout=subprocess.DEVNULL,
                                     stderr=subprocess.PIPE)
            self.children.append(owner)
            connections = [self.connection() for _ in range(3)]
            deadline = time.monotonic() + 4
            while not ready.exists() and time.monotonic() < deadline:
                time.sleep(.02)
            self.assertTrue(ready.exists(), 'Panel helpers did not initialize')
            self.groups.extend(json.loads(ready.read_text()))
            owner.terminate()
            owner.wait(timeout=2)
            for conn in connections:
                conn.settimeout(2)
                self.assertEqual(conn.recv(1), b'', 'A helper survived its panel')


if __name__ == '__main__':
    unittest.main()
