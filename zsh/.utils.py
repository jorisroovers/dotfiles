import sys


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


if __name__ == "__main__":
    # interpret first argument as function name, pass along other arguments
    globals()[sys.argv[1]](*sys.argv[2:])
