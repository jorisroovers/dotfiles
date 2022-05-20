import sys

RED = "\033[0;31m"
BLACK = "\033[0;30m"
GREEN = "\033[0;32m"
BROWN = "\033[0;33m"
BLUE = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN = "\033[0;36m"
LIGHT_GRAY = "\033[0;37m"
NC = "\033[0m"  # No Color


def _input_lines():
    return sys.stdin.read().split("\n")[:-1]


def prune(input_file):
    """Prune lines in STD that are present in input file"""
    prune_lines = open(input_file, "r").readlines()
    for line in sys.stdin:
        if line not in prune_lines:
            print(line.rstrip("\n"))


def join(join_str):
    """Joins line in STD together"""
    lines = _input_lines()
    print(join_str.join(lines))


def trimnl():
    """Trim empty (or whitespace) lines from STD"""
    lines = _input_lines()
    for line in lines:
        if line.strip() != "":
            print(line)


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
