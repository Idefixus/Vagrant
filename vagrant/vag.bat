@echo off
title Vagrant Set Up
rem echo Gib den Pfad der Vagrant file an die gestartet werden soll (empty string wenn dieser Pfad verwendet werden soll):
set /p userInput="Enter Vagrantfile path leave empty if this directory should be taken: "
echo This is the user input: %userInput%
if "%userInput%" == "" (
	echo true
	vagrant up
	vagrant ssh
) else ( 
	rem echo userInput + "\vagrant up" 
	echo false
)
pause