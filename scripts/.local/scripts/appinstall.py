#!/usr/bin/python3

import argparse
import os
import re
import shutil
import subprocess
import urllib.request
from pathlib import Path


def apt_installer(package):
    """Install a package using apt"""
    try:
        subprocess.run(["sudo", "apt", "update"], check=True)
        subprocess.run(["sudo", "apt", "install", "-y", package], check=True)
    except subprocess.CalledProcessError as e:
        print(f"APT installation failed: {e}")


def pacman_installer(package):
    """Install a package using pacman"""
    try:
        subprocess.run(["sudo", "pacman", "-Syu", package], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Pacman installation failed: {e}")


def get_command_version(command, formatter=None):
    """Get version of an installed command.

    Args:
        command: The command to check (e.g., 'nvim', 'fd', 'fzf')
        formatter: Optional function to format the output. If None, returns stripped output.

    Returns:
        Version string or None if command not found or error occurred
    """
    try:
        result = subprocess.run([command, "--version"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            if formatter:
                return formatter(result.stdout)
            else:
                return result.stdout.strip()
        return None
    except Exception:
        return None


def update_config_file(file_path, marker_name, content):
    """Updates a block of text in a file delimited by # start <marker_name> and # end <marker_name>.
    Creates the file and parent directories if they don't exist.

    Args:
        file_path: Path to the config file
        marker_name: Name of the marker (markers will be "# start marker_name" and "# end marker_name")
        content: Content to insert between the markers
    """
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


def create_symlink(bin_dir, source_command, link_name):
    """Create a symlink to a command in the bin directory.

    Args:
        bin_dir: Path to the bin directory where the symlink will be created
        source_command: The command to link from (e.g., 'fdfind')
        link_name: The name of the symlink (e.g., 'fd')
    """
    source_path = shutil.which(source_command)
    if not source_path:
        print(f"Error: Could not find {source_command} in system PATH.")
        return

    link_path = bin_dir / link_name
    if link_path.exists() or link_path.is_symlink():
        link_path.unlink()

    try:
        os.symlink(source_path, link_path)
        print(f"Symlinked {source_command} -> {link_path}")
    except Exception as e:
        print(f"Failed to create symlink: {e}")


class Installer:
    """Base class for all installers"""

    def __init__(self, installer_type, attributes):
        self.installer_type = installer_type
        self.attributes = attributes

    def get_version(self):
        """Return the current version of the installed application, or None if N/A"""
        raise NotImplementedError

    def install(self):
        """Install the application"""
        raise NotImplementedError

    def supported_installers(self):
        """Return a list of installer types this class supports, e.g., ['apt', 'pacman']"""
        raise NotImplementedError

    def app_name(self):
        """Return the application name. Override in subclasses for custom names."""
        raise NotImplementedError

    @classmethod
    def get_installers(cls):
        """Build and return a registry of all available installers from supported_installers() declarations"""
        registry = {}
        installers_to_register = [
            NvimInstaller,
            FdInstaller,
            FzfInstaller,
            LazyGitInstaller,
            BashProfileInstaller,
            BashrcInstaller,
        ]

        for installer_class in installers_to_register:
            instance = installer_class(None, None)
            app_name = instance.app_name
            for installer_type in instance.supported_installers():
                registry[(app_name, installer_type)] = installer_class

        return registry

    @classmethod
    def create_job(cls, installer_tuple, attributes):
        """Factory method to create an installer instance (Job) from an (app_name, installer_type) tuple.

        Args:
            installer_tuple: A (app_name, installer_type) tuple
            attributes: Installation attributes

        Returns:
            An installer instance or None if the tuple is not found in the registry
        """
        registry = cls.get_installers()
        if installer_tuple in registry:
            app_name, installer_type = installer_tuple
            installer_class = registry[installer_tuple]
            return installer_class(installer_type, attributes)
        return None


class NvimInstaller(Installer):
    def supported_installers(self):
        return ["appimage"]

    @property
    def app_name(self):
        return "nvim"

    def get_version(self):
        return get_command_version("nvim", formatter=lambda x: x.split('\n')[0])

    def install(self):
        url = "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        target = Path.home() / ".local" / "bin" / "nvim"

        try:
            urllib.request.urlretrieve(url, target)
            target.chmod(target.stat().st_mode | 0o100)
            print(f"Neovim installed to {target}")
        except Exception as e:
            print(f"Failed to download Neovim: {e}")


class FdInstaller(Installer):
    def supported_installers(self):
        return ["apt", "pacman"]

    @property
    def app_name(self):
        return "fd"

    def get_version(self):
        return get_command_version("fd")

    def install(self):
        if self.installer_type == "apt":
            apt_installer("fd-find")
            create_symlink(Path.home() / ".local" / "bin", "fdfind", "fd")
        elif self.installer_type == "pacman":
            pacman_installer("fd")


class FzfInstaller(Installer):
    def supported_installers(self):
        return ["apt"]

    @property
    def app_name(self):
        return "fzf"

    def get_version(self):
        return get_command_version("fzf")

    def install(self):
        apt_installer("fzf")


class LazyGitInstaller(Installer):
    def supported_installers(self):
        return ["apt"]

    @property
    def app_name(self):
        return "lazygit"

    def get_version(self):
        return get_command_version("lazygit")

    def install(self):
        apt_installer("lazygit")


class BashProfileInstaller(Installer):
    def supported_installers(self):
        return ["config"]

    @property
    def app_name(self):
        return "bash-profile"

    def get_version(self):
        return None

    def install(self):
        try:
            source_path = Path(self.attributes[0])
            content_to_add = source_path.read_text()
            profile_path = Path.home() / ".config" / "bash" / "profile_custom"

            update_config_file(
                file_path=profile_path,
                marker_name="custom_bash_profile",
                content=content_to_add
            )
        except IndexError:
            print("Error: No source file provided for bash_profile")
        except (OSError, IOError) as e:
            print(f"Error: Could not read source file {self.attributes[0] if self.attributes else 'unknown'}: {e}")


class BashrcInstaller(Installer):
    def supported_installers(self):
        return ["config"]

    @property
    def app_name(self):
        return "bashrc"

    def get_version(self):
        return None

    def install(self):
        if not self.attributes:
            print("Error: No source file provided for bashrc")
            return

        source_path = Path(self.attributes[0])
        if not source_path.exists():
            print(f"Error: Source file {source_path} not found")
            return

        bashrc = Path.home() / ".config" / "bash" / "bashrc_custom"
        bashrc.parent.mkdir(parents=True, exist_ok=True)
        bashrc.touch()


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

Status Check:
  appinstall.py -s -f <file>
  appinstall.py --status <application_name> <installer_type>

Examples:
  appinstall.py -f apps.txt
  appinstall.py -s -f apps.txt
  appinstall.py -s nvim appimage
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
        "-s", "--status",
        action="store_true",
        help="Check the installation status of applications instead of installing"
    )

    parser.add_argument(
        "app_args",
        nargs="*",
        help="Application name, installer type, and optional attributes (for interactive mode)"
    )    installers_to_run = installer.create_jobs(install_requests)

    for installer_obj in installers_to_run:
        installer.install(installer_obj)

if __name__ == "__main__":
    main()
