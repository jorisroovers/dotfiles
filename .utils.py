import inspect
import logging
import os
import sys

logging.basicConfig()
LOG = logging.getLogger(__name__)

# Workaround for dealing with broken pipes when piping to e.g. `head`
# https://stackoverflow.com/a/30091579/381010
from signal import signal, SIGPIPE, SIG_DFL

signal(SIGPIPE, SIG_DFL)

# Terminal colors
RED = "\033[0;31m"
BLACK = "\033[0;30m"
GREEN = "\033[0;32m"
BROWN = "\033[0;33m"
BLUE = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN = "\033[0;36m"
CYAN_BOLD = "\033[1;36m"
LIGHT_GRAY = "\033[0;37m"
NC = "\033[0m"  # No Color


########################################################################################################################
# Internal helper functions
########################################################################################################################


def _input_lines():
    # return sys.stdin.read().split("\n")
    lines = sys.stdin.read().split("\n")
    if lines[-1] == "":
        lines = lines[:-1]
    LOG.debug("lines: %s", lines)
    return lines


def _list_exported_funcs():
    func_tuples = inspect.getmembers(sys.modules[__name__], inspect.isfunction)
    func_tuples = [f for f in func_tuples if not f[0].startswith("_")]
    func_tuples = [f for f in func_tuples if f[0] not in ("signal")]
    return func_tuples


########################################################################################################################
# Alias installation
########################################################################################################################


def _install_aliases(script_invocation):
    """Print alias commands for all functions provided by this script. Use as eval ($ _u _install_aliases)"""
    print('alias myalias="echo foo"')
    for func_tuple in _list_exported_funcs():
        print(f'alias {func_tuple[0]}="{script_invocation} {func_tuple[0]}"')


########################################################################################################################
# Exported utility functions
########################################################################################################################


def noop():
    """Print every line passed to stdin"""
    lines = _input_lines()
    for line in lines:
        print(line)


def prune(input_file):
    """Prune lines in STDIN that are present in input file"""
    prune_lines = open(input_file, "r").readlines()
    for line in sys.stdin:
        if line not in prune_lines:
            print(line.rstrip("\n"))


def prunestr(*needles):
    """Prune lines in STDIN that contain any of the needles"""
    for line in sys.stdin:
        line = line.rstrip("\n")
        if line not in needles:
            print(line)


def join(join_str):
    """Joins line in STDIN together"""
    lines = _input_lines()
    print(join_str.join(lines))


def trimnl():
    """Trim empty (or whitespace) lines from STD"""
    lines = _input_lines()
    for line in lines:
        if line.strip() != "":
            print(line)


def trim():
    """Trim each line on from STDIN"""
    lines = _input_lines()
    for line in lines:
        stripped = line.strip()
        if stripped != "":
            print(stripped)


def split(delimiter=None):
    """Split lines in STDIN by delimiter"""
    lines = _input_lines()
    for line in lines:
        print("\n".join(line.split(delimiter)))


def wsplit():
    """Whitespace split: split lines in STDIN by whitespace"""
    split(None)


def lower():
    """Lowercase STDIN"""
    lines = _input_lines()
    for line in lines:
        print(line.lower())


def upper():
    """Uppercase STDIN"""
    lines = _input_lines()
    for line in lines:
        print(line.upper())


def prepend(prefix):
    """Prepend a string to each line in STDIN"""
    lines = _input_lines()
    for line in lines:
        print(f"{prefix}{line}")


def append(suffix):
    """Append a string to each line in STDIN"""
    lines = _input_lines()
    for line in lines:
        print(f"{line}{suffix}")


def wrap(prefix, suffix=None):
    """Append a string to each line in STDIN"""
    if suffix is None:
        suffix = prefix
    lines = _input_lines()
    for line in lines:
        print(f"{prefix}{line}{suffix}")


def unwrap(prefix, suffix=None):
    """Remove a string to each line in STDIN"""
    if suffix is None:
        suffix = prefix
    lines = _input_lines()
    for line in lines:
        if line.startswith(prefix) and line.endswith(suffix):
            print(line[len(prefix) : -len(suffix)])
        else:
            print(line)


def h():
    """Print this help message"""
    for func_tuple in _list_exported_funcs():
        print(f"{GREEN}{func_tuple[0]:<15}{NC}   {func_tuple[1].__doc__}")


def linetitle(message, linechar="="):
    """Prints a title line with a passed message"""
    # # +21 = 3*7 chars color codes in `message`` below
    columns = os.get_terminal_size().columns + 21
    message = f"{CYAN}{linechar * 3} {CYAN_BOLD}{message}{CYAN} "
    print(f"{message:{linechar}<{columns}}{NC}")


def linecompare(input_file1, input_file2):
    """Compare lines of 2 input files"""
    lines1 = open(input_file1, "r").readlines()
    lines2 = open(input_file2, "r").readlines()

    filename_col_width = max(len(input_file1), len(input_file2))

    # add padding to align the filename columns
    file1_prefix = input_file1.rjust(filename_col_width)
    file2_prefix = input_file2.rjust(filename_col_width)

    line_num = 0
    for line1, line2 in zip(lines1, lines2):
        # Determine whether lines are same
        line1 = line1.rstrip("\n")
        line2 = line2.rstrip("\n")
        if line1 == line2:
            result = f"{GREEN}S{NC}"
        else:
            result = f"{RED}D{NC}"

        # colorize lines based on character matching
        current_line_color = RED
        line1_colored = ""
        line2_colored = ""
        for i in range(max(len(line1), len(line2))):
            current_line_color = RED
            if i < len(line1) and i < len(line2) and line1[i] == line2[i]:
                current_line_color = GREEN

            if i < len(line1):
                line1_colored += current_line_color + line1[i]
            if i < len(line2):
                line2_colored += current_line_color + line2[i]

        line1_colored += NC
        line2_colored += NC

        # print the lines
        print(f"{file1_prefix}:L{line_num} | {result} | {line1_colored}")
        print(f"{file2_prefix}:L{line_num} | {result} | {line2_colored}")
        print()
        line_num += 1


if __name__ == "__main__":
    # interpret first argument as function name, pass along other arguments
    if len(sys.argv) >= 3 and sys.argv[2] == "--debug":
        LOG.setLevel(logging.DEBUG)
        LOG.debug(sys.argv[1])
        sys.argv.pop(2)
    globals()[sys.argv[1]](*sys.argv[2:])
