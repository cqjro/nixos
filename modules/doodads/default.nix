{ pkgs, ...}:
{

environment.systemPackages = with pkgs; [
	mtkclient # installing firmware, like the innioasis Y1
	rockbox-utility # open source firmware for digital audio players
	slsk-batchdl # batch installer for soulseek
	nicotine-plus # GUI for soulseek
];

}
