@echo off

git pull
git checkout FortressForever
git restore *

cd FortressForever/maps
for /R %%f in (*.bz2) do (
	7z x -y %%f
)	

move /Y *.bsp ../../../FortressForever/maps
move /Y *.res ../../../FortressForever/maps
move /Y *.txt ../../../FortressForever/maps

cd ..
robocopy models ../../FortressForever/models /e

cd ../../FortressForever-fastdl/FortressForever
robocopy materials ../../FortressForever/materials /e

cd ../../FortressForever-fastdl/FortressForever
robocopy sound ../../FortressForever/sound /e

cd ../../FortressForever-fastdl/FortressForever
robocopy particles ../../FortressForever/particles /e

cd ../../FortressForever-fastdl/FortressForever
robocopy scripts ../../FortressForever/scripts /e

cd ..
move /Y mapcycle.txt ../FortressForever/cfg
move /Y motd.txt ../FortressForever/cfg
cd ..
