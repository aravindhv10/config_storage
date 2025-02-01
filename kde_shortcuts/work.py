#!/usr/bin/python3
def do_print(asd):
    print("[services][net.local.M_A_" + str(asd) + ".desktop]")
    print("_launch=Meta+Alt+" + str(asd))
    print("")


mylist = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    "Q",
    "W",
    "E",
    "R",
    "T",
    "A",
    "S",
    "D",
    "F",
    "G",
]

for i in mylist:
    do_print(asd = i)
