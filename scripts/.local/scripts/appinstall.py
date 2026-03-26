#!/usr/bin/python3

import os
import shutil
import subprocess
import urllib.request
import argparse
from pathlib import Path
from collections import namedtuple

# Define the Job namedtuple
Job = namedtuple("Job", ["func", "args", "name"])

class AppInstaller:
    def __init__(self, apps_file):
        self.apps_file = apps_file
        self.home = Path.home()

        # Define the directory requirements
        self.required_dirs = [
            self.home / ".local" / "bin",
            self.home / ".local" / "scripts",
            self.home / ".config"
        ]

        self.bin_dir = self.home / ".local" / "bin"

        # Supported installers: (Application Name, Installer Type) -> Method
        self.installers = {
            ("nvim", "appimage"): self.install_nvim_appimage,
            ("fd", "apt"): self.install_fd_apt,
            ("fzf", "apt"): self.install_fzf_apt,
        }

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

    def ask_to_update(self, app_name):
        choice = input(f" {app_name} is already installed. Update? (y/N): ").lower()
        return choice == 'y'

    def create_symlink(self, source_command, link_name):
        source_path = shutil.which(source_command)
        if not source_path:
            print(f"Error: Could not find {source_command} in system PATH.")
            return

        link_path = self.bin_dir / link_name
        if link_path.exists() or link_path.is_symlink():
            link_path.unlink()

        try:
            os.symlink(source_path, link_path)
            print(f"Symlinked {source_command} -> {link_path}")
        except Exception as e:
            print(f"Failed to create symlink: {e}")

    # --- Installation Functions ---

    def install_nvim_appimage(self, attributes):
        if self.is_installed("nvim") and not self.ask_to_update("Neovim"):
            return

        url = "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        target = self.bin_dir / "nvim"

        print("Downloading Neovim AppImage...")
        try:
            urllib.request.urlretrieve(url, target)
            target.chmod(target.stat().st_mode | 0o100)
            print(f"Neovim installed to {target}")
        except Exception as e:
            print(f"Failed to download Neovim: {e}")

    def install_fd_apt(self, attributes):
        if self.is_installed("fd") and not self.ask_to_update("fd"):
            return

        print("Installing fd-find via apt...")
        try:
            subprocess.run(["sudo", "apt", "update"], check=True)
            subprocess.run(["sudo", "apt", "install", "-y", "fd-find"], check=True)
            self.create_symlink("fdfind", "fd")
        except subprocess.CalledProcessError as e:
            print(f"APT installation failed: {e}")

    def install_fzf_apt(self, attributes):
        pass

    # --- Core Processing ---

    def install(self, job):
        """Run the installation for the provided job"""
        print("-" * 30)
        print(f"Processing: {job.name}")
        job.func(job.args)

    def process_list(self):
        if not os.path.exists(self.apps_file):
            print(f"Error: File '{self.apps_file}' not found.")
            return

        jobs = []
        with open(self.apps_file, "r") as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                parts = line.split()
                if len(parts) < 2:
                    print(f"Malformed input on line {line_num}  - aborting")
                    exit(1)

                app_name, installer_type = parts[0], parts[1]
                attributes = parts[2:]

                installer_key = (app_name, installer_type)
                if installer_key in self.installers:
                    # Create an installation job
                    jobs.append(Job(
                        func=self.installers[installer_key],
                        args=attributes,
                        name=app_name
                    ))
                else:
                    print(f"No installer for {app_name} via {installer_type}")

        for job in jobs:
            self.install(job)

def main():
    parser = argparse.ArgumentParser(
        description="A modular application installer script.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Input File Format:
  The input file should contain one application per line:
  <application_name> <installer_type> [attributes...]

Example:
  # This is a comment
  nvim appimage
  fd apt
        """
    )

    parser.add_argument(
        "file",
        help="Path to the applications list file (required)"
    )

    args = parser.parse_args()

    installer = AppInstaller(args.file)
    installer.process_list()

if __name__ == "__main__":
    main()
