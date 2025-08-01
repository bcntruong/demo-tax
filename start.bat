@echo off
echo Starting Rails server and TailwindCSS watcher...
start cmd /k "rails server"
start cmd /k "rails tailwindcss:watch"
echo Servers started. Visit http://localhost:3000 in your browser.
