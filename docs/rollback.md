# Booting or activating an older generation

Every host keeps the newest 5 generations in its boot menu
(`boot.loader.*.configurationLimit = 5`, `modules/essentials/nix-gc.nix`). The
weekly `nh clean` (Sunday 03:00, `--keep 5 --keep-since 14d`) deletes a
generation only when it is both beyond the newest 5 **and** older than 14 days.
The cap only trims the menu; it does not delete anything. So a generation that
fell off the menu usually still exists for up to two weeks.

`nh clean` never rewrites the bootloader. Boot entries are rewritten only by a
`switch` or `boot`, so between a clean and the next switch the menu can still
list a generation whose closure is gone (it loads the kernel, then fails in
stage 2). Treat only the newest 5 entries as bootable.

## 1. List what exists

```bash
./rebuild.sh generations                          # number, date, commit/PR (run from a checkout)
nixos-rebuild list-generations                    # same data without the repo
ls -d /nix/var/nix/profiles/system-*-link         # the generation links on disk
```

A generation is available if `system-N-link` exists **and** its closure is
still in the store (`ls /nix/var/nix/profiles/system-N-link/` works and
`readlink -f` resolves to a real path).

## 2. It still exists: activate it

Boot any working entry first (the machine must be up), then:

```bash
sudo /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
```

Replace `N` with the generation number. The three actions differ in whether
they activate now and whether the boot default changes:

| Action | Activates now | Becomes the persistent boot default |
| --- | --- | --- |
| `switch` | yes | yes |
| `boot` | no | yes (takes effect at the next reboot, and stays the default after it) |
| `test` | yes | no (a reboot returns to the old default) |

`boot` is not a one-time setting. For a true one-shot boot into one entry use
the bootloader:

- systemd-boot (MENTICIDE, REGICIDE, CHRONOCIDE): `bootctl list`, then
  `sudo bootctl set-oneshot <entry-id>`; the saved default returns after that boot.
- GRUB (THEOCIDE): pick the entry in the GRUB menu at the console (always works).
  `sudo grub-reboot <entry>` only takes effect if GRUB is set to `default = "saved"`,
  which this repo does not do, so do not rely on it.

`nixos-rebuild switch --rollback` only goes back one generation, so it does not
help for anything older.

## 3. It was already cleaned: rebuild it from its commit

Each generation records its commit (`git-<sha>` in the boot label; `./rebuild.sh
generations` maps generation, commit and PR). Rebuild that commit **on THEOCIDE**
(only THEOCIDE builds other hosts; every other machine builds only itself):

```bash
git -C ~/.nixos worktree add ~/.t3/worktrees/.nixos/old <sha>
cd ~/.t3/worktrees/.nixos/old
./rebuild.sh build HOST
```

Then activate the result from a terminal on that host with
`switch-to-configuration` as above (`rebuild.sh switch` refuses anything but
`master`). This is slow and needs the old flake inputs to still be fetchable, so
it is a fallback.

## 4. Keep one generation for good

Root it so no clean can delete its closure (do this before the first weekly
clean on a machine you cannot reach, e.g. MENTICIDE):

```bash
sudo nix-store --add-root /nix/var/nix/gcroots/keep-gen-N -r /nix/var/nix/profiles/system-N-link
```

`nh clean` still removes the profile link and its menu entry, but the closure
survives and can be activated from its store path
(`sudo "$(readlink -f /nix/var/nix/gcroots/keep-gen-N)/bin/switch-to-configuration" switch`).
Remove the root with `sudo rm /nix/var/nix/gcroots/keep-gen-N` when it is no
longer needed.
