# Build files

`Release.ps1` builds the install and patch release zips: it bumps the game
version, launches a PBS debug compile and waits for you to confirm it
finished, tags the release, and produces both zips with forward-slash zip
entry paths (so they extract correctly on Linux, unlike the old Chasm
Zipper.jar output).

The compile step launches `Game.exe debug compile` and pauses for you to
confirm it's finished and press Enter — Game.exe opens its own debug console
rather than using the parent process's stdout, so the script can't reliably
capture or wait on that output itself.

Run it from this folder, e.g.:

```powershell
./Release.ps1 -Version 3.2.4
```

Add `-DryRun` to preview every action without touching the repo or
filesystem. Each step (`-SkipVersionBump`, `-SkipCompile`, `-SkipInstallZip`,
`-SkipPatchZip`, `-SkipTag`) can be skipped independently to test a step in
isolation or resume after a failure partway through. See
`Get-Help ./Release.ps1 -Full` for all parameters.

`install_files.txt` lists the root-level files/folders that make up the
install zip, one per line, relative to the repo root.

Output zips are written to `Releases/` (gitignored).
