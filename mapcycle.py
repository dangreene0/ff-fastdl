from os import listdir, path

def main():
    extension = ".bsp.bz2"
    dir = "FortressForever/maps"
        
    motd = """Map List:

"""

    f = open("mapcycle.txt", "w")
    for file in listdir(dir):
        if file.endswith(extension):
            f.write(path.join(file[:-8]) + "\n")
    f.close()

    fm = open("motd.txt", "w")
    fm.write(motd)
    for file in listdir(dir):
        if file.endswith(extension):
            fm.write(path.join(file[:-8]) + "\n")
    fm.close()
        
if __name__ == "__main__":
    main()

    