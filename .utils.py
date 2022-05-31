import inspect
import sys

# Workaround for dealing with broken pipes when piping to e.g. `head`
# https://stackoverflow.com/a/30091579/381010
from signal import signal, SIGPIPE, SIG_DFL

signal(SIGPIPE, SIG_DFL)


RED = "\033[0;31m"
BLACK = "\033[0;30m"
GREEN = "\033[0;32m"
BROWN = "\033[0;33m"
BLUE = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN = "\033[0;36m"
LIGHT_GRAY = "\033[0;37m"
NC = "\033[0m"  # No Color


########################################################################################################################
# Internal helper functions
########################################################################################################################


def _input_lines():
    return sys.stdin.read().split("\n")[:-1]


########################################################################################################################
# Exported utility functions
########################################################################################################################


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
    """Trim each line on from STD"""
    lines = _input_lines()
    for line in lines:
        stripped = line.strip()
        if stripped != "":
            print(stripped)


def split(delimiter):
    """Split lines in STD by delimiter"""
    lines = _input_lines()
    for line in lines:
        print("\n".join(line.split(delimiter)))


def wsplit():
    """Whitespace split: split lines in STDIN by whitespace"""
    split(None)


def lower():
    """Lowercase STD"""
    lines = _input_lines()
    for line in lines:
        print(line.lower())


def upper():
    """Uppercase STD"""
    lines = _input_lines()
    for line in lines:
        print(line.upper())


def h():
    """Print this help message"""
    func_tuples = inspect.getmembers(sys.modules[__name__], inspect.isfunction)
    func_tuples = [f for f in func_tuples if not f[0].startswith("_")]
    func_tuples = [f for f in func_tuples if f[0] not in ("signal")]
    for func_tuple in func_tuples:
        print(f"{GREEN}{func_tuple[0]:<15}{NC}   {func_tuple[1].__doc__}")


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
    globals()[sys.argv[1]](*sys.argv[2:])
