{ self, lib, ... }: with lib; let
	tv = n: "\${" + n + "}";
        rv = tv "resource.random_string.random.id";
	location = "us";
	region = "${location}-west1";
	zone = region + "-b";
	drv = self.packages.x86_64-linux.image;
	fileName = pipe drv [
		builtins.readDir
		attrNames
		(filter (hasPrefix "nixos-image"))
		head
	];
in {
	provider.google = {
		inherit region zone;
		project = rv;
	};
	terraform = {
		backend.local.path = "/tmp/gcp-test.tfstate";
		required_providers.google.source = "terranix.local/hashicorp/google";
	};
	variable = {
		billing_account = {
			type = "string";
			sensitive = true;
		};
		org_id = {
			type = "string";
			sensitive = true;
		};
	};
	resource = {
		random_string.random = {
			length = 16;
			special = false;
			upper = false;
			numeric = false;
		};

		google_project.project = {
			name = rv;
			project_id = rv;
			billing_account = tv "var.billing_account";
			org_id = tv "var.org_id";
			deletion_policy = "DELETE";
		};

		google_project_service.project = {
			project = tv "resource.google_project.project.id";
			service = "compute.googleapis.com";
			timeouts = {
				create = "30m";
				update = "40m";
			};
		};

		google_storage_bucket.images = {
			name = rv;
			force_destroy = true;
			inherit location;
		};

		google_storage_bucket_object.imagefile = {
			name = fileName;
			source = concatStringsSep "/" [ drv fileName ];
			bucket = tv "google_storage_bucket.images.id";
		};

		google_compute_image.image = {
			name = rv;
			project = rv;
			raw_disk.source = tv "google_storage_bucket_object.imagefile.media_link";
		};

		google_compute_instance.instance = {
			name = rv;

			boot_disk = {
				auto_delete = true;

				initialize_params = {
					image = tv "resource.google_compute_image.image.id";
					size = 10;
				};
			};

			machine_type = "e2-small";

			network_interface = {
				access_config = {};
				subnetwork = "default";
			};

			scheduling = {
				automatic_restart = false;
				on_host_maintenance = "TERMINATE";
				preemptible = true;
				provisioning_model = "SPOT";
			};
		};
	};
}
