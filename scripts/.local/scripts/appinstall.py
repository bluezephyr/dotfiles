#!/usr/bin/python3

import argparse
import os
import shutil
from pathlib import Path

from installers import Installer


def read_installations(file_path):
    """Read installation tuples from a file.

    File format: One tuple per line (comments starting with # are ignored):
        <application_name> <installer_type> [attributes...]

    Returns: List of tuples [(app_name, installer_type, [attributes...]), ...]
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File '{file_path}' not found.")

    tuples = []
    with open(file_path, "r") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            if len(parts) < 2:
                print(f"Malformed input on line {line_num}: aborting")
                exit(1)

            app_name, installer_type = parts[0], parts[1]
            attributes = parts[2:]
            tuples.append((app_name, installer_type, attributes))

    return tuples


class AppInstaller:
    def __init__(self):
        self.home = Path.home()

        # Define the directory requirements
        self.required_dirs = [
            self.home / ".local" / "bin",
            self.home / ".local" / "scripts",
            self.home / ".config"
        ]

        self.bin_dir = self.home / ".local" / "bin"

        # Initialize environment and cleanup
        self._ensure_env_exists()
        self.cleanup_broken_symlinks()

    def _ensure_env_exists(self):
        """Iterates through required directories and creates them if missing."""
        for directory in self.required_dirs:
            if not directory.exists():
                directory.mkdir(parents=True, exist_ok=True)

    def cleanup_broken_symlinks(self):
        """Scans the bin directory and removes dangling links."""
        if self.bin_dir.exists():
            for item in self.bin_dir.iterdir():
                if item.is_symlink() and not item.exists():
                    print(f"Removing broken link: {item.name}")
                    item.unlink()

    def is_installed(self, cmd):
        return shutil.which(cmd) is not None

    def ask_to_update(self, app_name, installer=None):
        version_str = ""
        if installer:
            try:
                version = installer.get_version()
                if version:
                    version_str = f" (version: {version})"
            except Exception:
                pass

        choice = input(f" {app_name} is already installed{version_str}. Update? (y/N): ").lower()
        return choice == 'y'

    def list_installers(self):
        """Display all available installers."""
        registry = Installer.get_installers()
        if not registry:
            print("No installers available.")
            return

        print("Available installers:")
        print("-" * 50)
        print(f"  {'Application':<20} {'Type'}")
        print("-" * 50)

        for (app_name, installer_type) in sorted(registry.keys()):
            print(f"  {app_name:<20} {installer_type}")


    # --- Core Processing ---

    def install(self, installer):
        """Run the installation for the provided installer"""
        app_name = installer.app_name
        print("-" * 30)
        print(f"Installing: {app_name}")
        if self.is_installed(app_name) and not self.ask_to_update(app_name, installer):
            return

        installer.install()

    def create_jobs(self, installation_tuples):
        """Convert installation tuples into a list of installer objects.

        Args:
            installation_tuples: List of tuples [(app_name, installer_type, [attributes...]), ...]

        Returns: List of installer objects ready for installation
        """
        installers = []
        for app_name, installer_type, attributes in installation_tuples:
            installer_key = (app_name, installer_type)
            installer = Installer.create_job(installer_key, attributes)
            if installer:
                installers.append(installer)
            else:
                print(f"No installer for {app_name} via {installer_type}")

        return installers


def main():
    parser = argparse.ArgumentParser(
        description="A modular application installer script.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Input File Mode:
  appinstall.py -f <file>
  The input file should contain one application per line:
  <application_name> <installer_type> [attributes...]

Interactive Mode:
  appinstall.py <application_name> <installer_type> [attributes...]
  Install a single application directly from command line arguments.

Examples:
  appinstall.py -f apps.txt
  appinstall.py nvim appimage
  appinstall.py fd apt
        """
    )

    parser.add_argument(
        "-f", "--file",
        help="Path to the applications list file"
    )

    parser.add_argument(
        "-l", "--list",
        action="store_true",
        help="List all available installers"
    )

    parser.add_argument(
        "app_args",
        nargs="*",
        help="Application name, installer type, and optional attributes (for interactive mode)"
    )

    args = parser.parse_args()

    installer = AppInstaller()

    if args.list:
        installer.list_installers()
        return

    if args.file:
        try:
            installations = read_installations(args.file)
        except FileNotFoundError as e:
            parser.error(str(e))
    elif args.app_args:
        if len(args.app_args) < 2:
            parser.error("Interactive mode requires at least <application_name> and <installer_type>")
        app_name = args.app_args[0]
        installer_type = args.app_args[1]
        attributes = args.app_args[2:] if len(args.app_args) > 2 else []
        installations = [(app_name, installer_type, attributes)]

    installers_to_run = installer.create_jobs(installations)

    for installer_obj in installers_to_run:
        installer.install(installer_obj)

if __name__ == "__main__":
    main()
