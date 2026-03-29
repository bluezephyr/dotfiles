#!/usr/bin/python3

import argparse
import os
import re
import shutil
import subprocess
import urllib.request
from collections import namedtuple
from pathlib import Path

# Define the Job namedtuple
Job = namedtuple("Job", ["installer", "args", "name"])

# Define the Installer namedtuple
Installer = namedtuple("Installer", ["installer", "version_check"])


def read_installation_tuples(file_path):
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

        # Version check methods
        def check_nvim_version():
            try:
                result = subprocess.run(["nvim", "--version"], capture_output=True, text=True, timeout=5)
                return result.stdout.split('\n')[0] if result.returncode == 0 else None
            except Exception:
                return None

        def check_fd_version():
            try:
                result = subprocess.run(["fd", "--version"], capture_output=True, text=True, timeout=5)
                return result.stdout.strip() if result.returncode == 0 else None
            except Exception:
                return None

        def check_fzf_version():
            try:
                result = subprocess.run(["fzf", "--version"], capture_output=True, text=True, timeout=5)
                return result.stdout.strip() if result.returncode == 0 else None
            except Exception:
                return None

        # Supported installers: (Application Name, Installer Type) -> Installer
        self.installers = {
            ("nvim", "appimage"): Installer(self.install_nvim_appimage, check_nvim_version),
            ("fd", "apt"): Installer(self.install_fd_apt, check_fd_version),
            ("fzf", "apt"): Installer(self.install_fzf_apt, check_fzf_version),
            ("bash-profile", "config"): Installer(self.install_bash_profile, None),
            ("bashrc", "config"): Installer(self.install_bashrc, None),
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

    def ask_to_update(self, app_name, version_check=None):
        version_str = ""
        if version_check:
            try:
                version = version_check()
                if version:
                    version_str = f" (version: {version})"
            except Exception:
                pass
        
        choice = input(f" {app_name} is already installed{version_str}. Update? (y/N): ").lower()
        return choice == 'y'

    def list_installers(self):
        """Display all available installers."""
        if not self.installers:
            print("No installers available.")
            return

        print("Available installers:")
        print("-" * 50)
        print(f"  {'Application':<20} {'Type'}")
        print("-" * 50)

        for (app_name, installer_type) in sorted(self.installers.keys()):
            print(f"  {app_name:<20} {installer_type}")

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
    def apt_installer(self, package):
        try:
            subprocess.run(["sudo", "apt", "update"], check=True)
            subprocess.run(["sudo", "apt", "install", "-y", package], check=True)
        except subprocess.CalledProcessError as e:
            print(f"APT installation failed: {e}")

    def install_nvim_appimage(self, attributes):
        url = "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        target = self.bin_dir / "nvim"

        try:
            urllib.request.urlretrieve(url, target)
            target.chmod(target.stat().st_mode | 0o100)
            print(f"Neovim installed to {target}")
        except Exception as e:
            print(f"Failed to download Neovim: {e}")

    def install_fd_apt(self, attributes):
        self.apt_installer("fd-find")
        self.create_symlink("fdfind", "fd")

    def install_fzf_apt(self, attributes):
        self.apt_installer("fzf")

    def update_config_file(self, file_path, marker_name, content):
        """Updates a block of text in a file delimited by # start <marker_name> and # end <marker_name>.
        Creates the file and parent directories if they don't exist. """
        target = Path(file_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.touch()

        start_marker = f"# start {marker_name}"
        end_marker = f"# end {marker_name}"
        new_block = f"{start_marker}\n{content.strip()}\n{end_marker}"

        current_content = target.read_text()

        # Use re.escape so marker names with special chars don't break the regex
        pattern = re.compile(
            rf"{re.escape(start_marker)}.*?{re.escape(end_marker)}",
            re.DOTALL
        )

        if pattern.search(current_content):
            updated_content = pattern.sub(new_block, current_content)
        else:
            # Ensure a newline if the file has content but doesn't end with a newline
            prefix = "\n" if current_content and not current_content.endswith("\n") else ""
            updated_content = f"{current_content}{prefix}{new_block}\n"

        target.write_text(updated_content)

    def install_bash_profile(self, attributes):
        if not attributes:
            print("Error: No source file provided for bash_profile")
            return

        source_path = Path(attributes[0])
        if not source_path.exists():
            print(f"Error: Source file {source_path} not found")
            return

        profile_path = self.home / ".config" / "bash" / "profile_custom"
        content_to_add = source_path.read_text()

        self.update_config_file(
            file_path=profile_path,
            marker_name="custom_bash_profile",
            content=content_to_add
        )

    def install_bash_profile(self, attributes):
        try:
            source_path = Path(attributes[0])
            content_to_add = source_path.read_text()
            profile_path = self.home / ".config" / "bash" / "profile_custom"

            self.update_config_file(
                file_path=profile_path,
                marker_name="custom_bash_profile",
                content=content_to_add
            )
        except IndexError:
            print("Error: No source file provided for bash_profile")
        except (OSError, IOError) as e:
            print(f"Error: Could not read source file {attributes[0] if attributes else 'unknown'}: {e}")


    def install_bashrc(self, attributes):
        if not attributes:
            print("Error: No source file provided for bashrc")
            return

        source_path = Path(attributes[0])
        if not source_path.exists():
            print(f"Error: Source file {source_path} not found")
            return

        bashrc = self.home / ".config" / "bash" / "bashrc_custom"
        bashrc.parent.mkdir(parents=True, exist_ok=True)
        bashrc.touch()


    # --- Core Processing ---

    def install(self, job):
        """Run the installation for the provided job"""
        print("-" * 30)
        print(f"Installing: {job.name}")
        if self.is_installed(job.name) and not self.ask_to_update(job.name, job.installer.version_check):
            return

        job.installer.installer(job.args)

    def create_jobs(self, installation_tuples):
        """Convert installation tuples into a list of Job objects.

        Args:
            installation_tuples: List of tuples [(app_name, installer_type, [attributes...]), ...]

        Returns: List of Job objects ready for installation
        """
        jobs = []
        for app_name, installer_type, attributes in installation_tuples:
            installer_key = (app_name, installer_type)
            if installer_key in self.installers:
                installer_info = self.installers[installer_key]
                jobs.append(Job(
                    installer=installer_info,
                    args=attributes,
                    name=app_name
                ))
            else:
                print(f"No installer for {app_name} via {installer_type}")

        return jobs


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
            installation_tuples = read_installation_tuples(args.file)
        except FileNotFoundError as e:
            parser.error(str(e))
    elif args.app_args:
        if len(args.app_args) < 2:
            parser.error("Interactive mode requires at least <application_name> and <installer_type>")
        app_name = args.app_args[0]
        installer_type = args.app_args[1]
        attributes = args.app_args[2:] if len(args.app_args) > 2 else []
        installation_tuples = [(app_name, installer_type, attributes)]

    jobs = installer.create_jobs(installation_tuples)

    for job in jobs:
        installer.install(job)

if __name__ == "__main__":
    main()
