from os import listdir
import tarfile

def main():
    extension = ".bsp"
    dir = "FortressForever/maps"

    print("Begging batch map compression.")
    for file in listdir(dir):
        if file.endswith(extension):
            with tarfile.open(f'{dir}/{file}.bz2', 'w:bz2') as tar:
                print(f"Compressing: {file}")
                tar.add(f'{dir}/{file}')
                tar.close()
    
    print("Batch map compression complete.")

if __name__ == "__main__":
    main()


        
            