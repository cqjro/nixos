#!/usr/bin/env bash
# Self-test for secret-guard.sh. Fake credentials are assembled at run time so no
# token-shaped string is ever committed. Usage: secret-guard-test.sh [guard-cmd]
set -u
guard="${1:-$(dirname "${BASH_SOURCE[0]}")/secret-guard.sh}"
rep() { printf '%*s' "$2" '' | tr ' ' "$1"; }

fail=0
check() { # name expect(block|pass) mode json
	out="$($guard "$3" <<<"$4" 2>&1)"
	got=pass
	[ -n "$out" ] && got=block
	if [ "$got" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (wanted $2, got $got)"; fail=1; fi
}
prompt() { jq -n --arg p "$1" '{prompt: $p}'; }
tool() { jq -n --arg n "$1" --arg c "$2" '{tool_name: $n, tool_input: {command: $c, content: $c}}'; }
toolp() { jq -n --arg n "$1" --arg k "$2" --arg v "$3" '{tool_name: $n, tool_input: {($k): $v}}'; } # file-reading tools: one path argument

gh="gh$(rep p 0)p_$(rep a 36)"
ant="sk-ant-$(rep b 30)"
pem="$(rep - 5)BEGIN OPENSSH PRIVATE KEY$(rep - 5)"
cf="{\"AccountTag\":\"x\",\"TunnelSecret\":\"y\"}"
aws="AKIA$(rep A 16)"
tskey="tskey-auth-$(rep c 20)"

check "github token blocks"        block prompt "$(prompt "here is my token $gh please push")"
check "anthropic key blocks"       block prompt "$(prompt "key: $ant")"
check "private key blocks"         block prompt "$(prompt "$pem")"
check "cloudflared creds block"    block prompt "$(prompt "$cf")"
check "aws key blocks"             block prompt "$(prompt "$aws")"
check "tailscale key blocks"       block prompt "$(prompt "$tskey")"
check "assignment (weak) blocks"   block prompt "$(prompt "ADMIN_PASSWORD=$(rep x 20)")"
check "assignment bypass passes"   pass  prompt "$(prompt "[allow-secret-pattern] ADMIN_PASSWORD=$(rep x 20)")"
check "strong ignores bypass"      block prompt "$(prompt "[allow-secret-pattern] $gh")"
check "plain prose passes"         pass  prompt "$(prompt "please rotate the miniflux password and update docs/secrets.md")"
check "nix store path passes"      pass  prompt "$(prompt "/nix/store/$(rep a 32)-glance-0.8")"
check "40-hex commit sha passes"   pass  prompt "$(prompt "see commit $(rep a 40)")"
check "empty prompt passes"        pass  prompt '{"prompt":""}'
check "garbage stdin fails open"   pass  prompt 'not json'
check "tool: bash with token asks" block tool   "$(tool Bash "curl -H 'Authorization: Bearer $(rep Z 30)' https://example.com")"
check "tool: write with key denies" block tool  "$(tool Write "$pem")"
check "tool: ordinary bash passes" pass  tool   "$(tool Bash "./rebuild.sh build REDRUM")"
check "tool: nix assignment passes" pass tool   "$(tool Edit "password = config.sops.secrets.x.path;")"
check "tool: git add firmware asks"   block tool   "$(tool Bash "git add -f modules/hosts/REDRUM/firmware/brcm/x.bin")"
check "tool: git add blob ext asks"   block tool   "$(tool Bash "git add some.clm_blob")"
check "tool: git add docs passes"     pass  tool   "$(tool Bash "git add docs/firmware.md modules/hosts/firmware.nix")"
check "tool: git commit msg passes"   pass  tool   "$(tool Bash "git commit -m \"firmware: use requireFile\"")"
check "tool: Write mentioning git add passes" pass tool "$(tool Write "run: git add -f modules/hosts/REDRUM/firmware/brcm/x.bin")"
check "read: firmware-src asks"           block tool "$(toolp Read file_path /var/lib/firmware-src/REDRUM/brcm/a.txt)"
check "read: hosts firmware dir asks"     block tool "$(toolp Grep path modules/hosts/REDRUM/firmware/brcm)"
check "read: clm_blob asks"               block tool "$(toolp Read file_path /tmp/x.clm_blob)"
check "read: firmware doc passes"         pass  tool "$(toolp Read file_path /home/u/.nixos/docs/firmware.md)"
check "read: ordinary nix file passes"    pass  tool "$(toolp Read file_path /home/u/.nixos/modules/system/t2-firmware.nix)"
check "grep: pattern naming brcmfmac ok"  pass  tool "$(jq -n '{tool_name:"Grep",tool_input:{pattern:"brcmfmac",path:"."}}')"
check "bash: cat firmware-src asks"       block tool "$(tool Bash "cat /var/lib/firmware-src/REDRUM/brcm/a.txt")"
check "bash: strings on firmware asks"    block tool "$(tool Bash "strings hosts/REDRUM/firmware/brcm/x.bin | head")"
check "bash: ls firmware-src passes"      pass  tool "$(tool Bash "ls /var/lib/firmware-src")"
check "bash: t2-firmware-import passes"   pass  tool "$(tool Bash "nix run .#t2-firmware-import -- REDRUM")"

exit "$fail"
