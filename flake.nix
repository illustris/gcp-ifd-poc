{
	description = "A very basic flake";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
		nixpkgs-patch.url = "github:illustris/nixpkgs?ref=gcp-ifd";
		terranix = {
			url = "github:terranix/terranix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		registry = {
			url = "github:illustris/terranix-tofu-registry";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, nixpkgs-patch, terranix, registry }: let
		inherit (nixpkgs) lib;
	in {

		nixosConfigurations = {
			before = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix" ];
			};
			after = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [ "${nixpkgs-patch}/nixos/modules/virtualisation/google-compute-image.nix" ];
			};
		};

		images.x86_64-linux = with self.nixosConfigurations; {
			imageBefore = before.config.system.build.googleComputeImage;
			imageAfter = after.config.system.build.googleComputeImage;
		};

		packages.x86_64-linux = with self.nixosConfigurations; {
			toplevelBefore = before.config.system.build.toplevel;
			toplevelAfter = after.config.system.build.toplevel;
			tf = terranix.lib.terranixConfiguration {
				system = "x86_64-linux";
				extraArgs = { inherit self; };
				modules = [
					./tf
				];
			};
		} // self.images.x86_64-linux;

		apps.x86_64-linux = (lib.genAttrs [ "plan" "apply" "destroy" "shell" "show" ] (n: {
			type = "app";
			program = builtins.toString (registry.lib.tofuScriptWithPlugins {
				system = "x86_64-linux";
				plugins.hashicorp.google = null; # use latest version
				script = lib.concatLines [
					". ${./gcloud-auth.sh}"
					({
						shell = "bash";
					}.${n} or "tofu ${n}")
				];
				init = true;
				tfConfig = self.packages.x86_64-linux.tf;
			});
		}));
	};
}
