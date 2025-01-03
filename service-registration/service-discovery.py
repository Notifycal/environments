#!/usr/bin/python3

import sys
import os
import subprocess
import json
import re
from string import Template
import argparse


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate a configuration file with interpolated values from SSM."
    )
    parser.add_argument(
        "--environment", required=True, help="Environment (e.g., 'prod', 'dev')"
    )
    parser.add_argument(
        "--mappings_file",
        required=False,
        help="Path to the mappings JSON file. Defaults to mapping.json",
    )
    parser.add_argument("--skel_file", required=True, help="Path to the skeleton file")
    parser.add_argument(
        "--aws_region", required=False, help="AWS region (e.g., 'eu-west-1')"
    )

    return parser.parse_args()


def find_interpolation_keys(skel):
    # A interpolation key is of this shape: ${keyToInterpolate}
    # Use a regular expression to find all `${...}` placeholders
    pattern = re.compile(r"\$\{(.*?)\}")
    matches = pattern.findall(skel)

    return matches


def get_ssm_parameter(parameter_name, aws_region):
    try:
        command = [
            "aws",
            "ssm",
            "get-parameter",
            "--name",
            parameter_name,
            "--with-decryption",
            "--query",
            "Parameter.Value",
            "--output",
            "text",
        ]

        if aws_region:
            command.extend(["--region", aws_region])

        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(
            f"Error fetching parameter {parameter_name}: {e.stderr.strip()}\n",
            file=sys.stderr,
        )
        return None
    except Exception as e:
        print(f"Unexpected error: {e}\n", file=sys.stderr)
        return None


def interpolate_skeleton(skel, resolved):
    """Substitute placeholders in the skeleton with resolved values."""
    skel_template = Template(skel)
    return skel_template.safe_substitute(resolved)


def main(args):
    if args.mappings_file is not None:
        mappings_file = args.mappings_file
    else:
        mappings_file_name = "mappings.json"
        print(
            f"No mappings_file found, defaulting to: {mappings_file_name}",
            file=sys.stderr,
        )

        script_dir = os.path.dirname(os.path.abspath(__file__))
        mappings_file = os.path.join(script_dir, mappings_file_name)

    # Load mappings and skel files
    with open(mappings_file, "r") as f:
        mappings = json.load(f)

    with open(args.skel_file, "r") as file:
        skel = file.read()

    # find interpolation keys in the skel file
    interpolation_keys = find_interpolation_keys(skel)
    print("Found potential interpolations in file:", file=sys.stderr)
    for placeholder in interpolation_keys:
        print(f"- {placeholder}", file=sys.stderr)
    print("", file=sys.stderr)  # New line

    # filter only the desired keys from mappings (source of truth)
    resolved = {}
    for key, value in mappings.items():
        if key in interpolation_keys:
            # interpolate `environment` in the value (SSM parameter name)
            ssm_path = Template(value).safe_substitute(environment=args.environment)
            # and retrieve the value from SSM
            ssm_value = get_ssm_parameter(ssm_path, args.aws_region)
            # wrapping in single quotes to replace the whole value,
            # and so we can set values to null too
            if ssm_value is not None:
                resolved[key] = f"'{ssm_value}'"

    # Check what won't be resolved and resolve to null
    unresolved_keys = [x for x in interpolation_keys if x not in resolved.keys()]
    if len(unresolved_keys) > 0:
        print(
            "Unresolved placeholders found (and automatically set to null):",
            file=sys.stderr,
        )
        for placeholder in unresolved_keys:
            resolved[placeholder] = "null"
            print(f"- {placeholder}", file=sys.stderr)
        print("", file=sys.stderr)  # New line
        print(
            "Please ensure all mappings are correct, as well as the skeleton file.\n",
            file=sys.stderr,
        )
    else:
        print(
            "All placeholders have been successfully interpolated.\n", file=sys.stderr
        )

    # Interpolate skel file
    final_config = interpolate_skeleton(skel, resolved)
    print(final_config)


if __name__ == "__main__":
    args = parse_args()
    main(args)
