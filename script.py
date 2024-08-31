import os
import json
import zipfile
from pathlib import Path

# Define the mods dir
MODS_DIR = Path(
    "~/.local/share/PrismLauncher/instances/Alana/.minecraft/mods"
).expanduser()

# Define tags to extract from fabric.mod.json
JSON_TAGS = ["id", "name", "version", "description"]

# List to hold all mod objects
mods_list = []


def parse_json(tags: list[str]):
    """Extracts the specified tags from the fabric.mod.json file of each mod in the mods directory. Adds them as mod objects.

    Args:
        tags (list[str]): A list of tags defined as strings to extract from the JSON
    """
    # Loop through each .jar file in the directory
    for jar_file in MODS_DIR.glob("*.jar"):
        with zipfile.ZipFile(jar_file, "r") as zip_ref:
            # Check if fabric.mod.json exists in the .jar file
            if "fabric.mod.json" in zip_ref.namelist():
                # Extract the fabric.mod.json file content
                with zip_ref.open("fabric.mod.json") as json_file:
                    try:
                        # Load and clean the JSON content
                        json_content = json_file.read().decode("utf-8")
                        # Replace control characters
                        clean_json_content = "".join(
                            c for c in json_content if c >= " "
                        )
                        # Parse JSON
                        data = json.loads(clean_json_content)

                        # Get the modid value (used as the object's name)
                        modid = data.get("id", "unknown_modid")

                        # Create a dictionary for the mod object with other tags as attributes
                        mod_object = {
                            "name": modid,
                            **{
                                tag: data.get(tag, "N/A") for tag in tags if tag != "id"
                            },
                        }

                        # Append the mod object to the list
                        mods_list.append(mod_object)

                    except json.JSONDecodeError:
                        print(f"Error: Failed to parse JSON from {jar_file}")
            else:
                print(f"Warning: fabric.mod.json not found in {jar_file}")
    return mods_list


mods_list = parse_json(JSON_TAGS)

# Output the list of mod objects
for mod in mods_list:
    print(mod)
