{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
	packages = [
		(pkgs.python3.withPackages (ps: with ps; [
    	google-api-python-client
    	google-auth-httplib2
    	google-auth-oauthlib
    	requests
  	]))
	];

}
