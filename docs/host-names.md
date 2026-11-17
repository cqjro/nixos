# Host names

Every machine is named after a "-cide" term (killing or erasure). This file is
the naming register: which name is in use, what it means, the names it
replaced, and the shortlist of candidates for the next machine. The full
definitions of every term considered live in
[`glossary-of-killing-and-erasure-terms.md`](glossary-of-killing-and-erasure-terms.md).

## In use

| Host | Term | Meaning | Machine | Former name |
| --- | --- | --- | --- | --- |
| `THEOCIDE` | Theocide (Greek *theos*, "god") | The killing of a god. | Desktop (NVIDIA, Hyprland, games) | `GOD-KILLER` |
| `MENTICIDE` | Menticide (Latin *mens*, "mind") | The systematic undermining and destruction of a person's mind, beliefs and free will through brainwashing or psychological torture. | Headless T2 Mac server | `REDRUM` |
| `REGICIDE` | Regicide (Latin *rex*, "king") | Killing a monarch, king or queen. | T2 MacBook (touchbar) laptop | `LittleNix` |
| `CHRONOCIDE` | Chronocide (Greek *chronos*, "time") | The destruction or "killing" of time; used for wasting time and, in speculative fiction, for destroying timelines. | MacBook Air early 2015 11-inch, 4 GB (niri) | new |

Names are the exact strings used in `modules/hosts/<NAME>/`, the
`nixosConfigurations` attribute, `networking.hostName` and the module fragment
names. They are upper case and have no hyphen, so no fragment needs quoting.

## Candidates for the next machine

Definitions are quoted from the glossary. Spelling follows the glossary
(`Onomasticide`, which the shortlist originally gave as "Onamasticide").

| Term | Definition |
| --- | --- |
| Onomasticide | The erasure or "killing" of a name, stripping a being of its true identity. |
| Noeticide | The destruction of intellect, thought, or collective consciousness (Greek *noetikos*, "intellectual"). |
| Essenticide | The destruction of a thing's core nature or fundamental truth, leaving behind a hollow shell (Latin *essentia*, "being/essence"). |
| Telosicide | The destruction of ultimate purpose, destiny, or end goals, leaving reality directionless (Greek *telos*, "end/purpose"). |
| Epistemicide | The systematic destruction or erasure of an entire system of knowledge or way of understanding the world (Greek *episteme*, "knowledge"). |
| Veriticide | The murder of objective truth, rendering reality entirely subjective or deceptive (Latin *veritas*, "truth"). |
| Semanticide | The destruction of meaning itself, stripping words, symbols, and actions of any significance (Greek *semantikos*, "significant"). |
| Suigenericide | Literally "the killing of one's own kind" or "destroying something entirely unique" (Latin *sui generis*, "of its own kind"). |

Theocide, Menticide and Chronocide were also on the shortlist and are now taken
(see the table above).

## Adding a host

1. Pick a free name from the candidates (or the glossary) and add a row to
   "In use" in the same change.
2. Create `modules/hosts/<NAME>/` with `machine.nix`, `hardware.nix`,
   `home.nix` (and `monitors.nix` if it has a graphical session), register it in
   `modules/hosts/host.nix`, and add it to the PR template, `README.md`'s
   machine table and `docs/schedules/host-scopes.json` if it needs a scope.
3. Keep names upper case, hyphen-free and unique case-insensitively
   (`rebuild.sh` matches `hostname` exactly).
