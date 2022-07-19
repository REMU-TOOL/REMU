#!/usr/bin/env python3

import os
import sys
import subprocess

def run_cmd(cmd, log):
    process = subprocess.Popen(
        'stdbuf -o0 ' + cmd,
        shell=True,
        bufsize=0,
        stdin=sys.stdin,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )

    tee_process = subprocess.Popen(
        f"tee {log}",
        shell=True,
        bufsize=0,
        stdin=process.stdout
    )

    process.wait()
    tee_process.wait()
    return process.returncode

def get_list(suite=None):
    path = os.path.dirname(__file__) + "/"
    if suite:
        path += suite
    path += "/list.txt"

    with open(path, 'r') as f:
        return [line.rstrip('\n') for line in f.readlines()]

if len(sys.argv) == 1:
    print("Usage:", file=sys.stderr)
    print(sys.argv[0] + " run [{<suite> | <suite>.<test>} ...]", file=sys.stderr)
    print(sys.argv[0] + " clean [{<suite> | <suite>.<test>} ...]", file=sys.stderr)
    print("All tests will be included if no suite or test is specified.", file=sys.stderr)
    exit(1)

command = sys.argv[1]

if not command in ['run', 'clean']:
    print(f"Unrecognized command: {command}", file=sys.stderr)
    exit(1)

all_tests = {}
for suite in get_list():
    all_tests[suite] = get_list(suite)

included_tests = []

for i in range(2, len(sys.argv)):

    arg = sys.argv[i].split('.')

    if len(arg) == 1:
        suite = arg[0]
        if not suite in all_tests:
            print(f"Suite {suite} does not exist", file=sys.stderr)
            exit(1)
        for test in all_tests[suite]:
            included_tests.append((suite, test))

    elif len(arg) == 2:
        suite = arg[0]
        test = arg[1]
        if not suite in all_tests:
            print(f"Suite {suite} does not exist", file=sys.stderr)
            exit(1)
        if not test in all_tests[suite]:
            print(f"Test {suite}.{test} does not exist", file=sys.stderr)
            exit(1)
        included_tests.append((suite, test))

    else:
        print(f"Invalid format: {sys.argv[i]}", file=sys.stderr)
        exit(1)

if len(included_tests) == 0:
    for suite in all_tests:
        for test in all_tests[suite]:
            included_tests.append((suite, test))

PASS_TEXT = "\033[32m[PASS]\033[39m"
FAIL_TEXT = "\033[31m[FAIL]\033[39m"

path = os.path.dirname(__file__)

if command == 'run':
    os.makedirs(f"{path}/log", exist_ok=True)
    results = []

    for (suite, test) in included_tests:
        print(f"Running {suite}.{test} ...", file=sys.stderr)
        log = f"{path}/log/{suite}.{test}.log"
        rc = run_cmd(f"make -C {path}/{suite}/{test}", log)
        passed = True

        if rc != 0:
            passed = False

        with open(log, 'r') as f:
            text = f.read()
            if 'failed' in text: # workaround for cocotb test
                passed = False

        results.append((suite, test, passed))

    for (suite, test, passed) in results:
        print(f"{PASS_TEXT if passed else FAIL_TEXT} {suite}.{test}", file=sys.stderr)

elif command == 'clean':
    for (suite, test) in included_tests:
        print(f"Cleaning {suite}.{test} ...", file=sys.stderr)
        os.system(f"cd {path} && make -C {suite}/{test} clean")
        os.system(f"cd {path} && rm -rf log")
