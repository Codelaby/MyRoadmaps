## Usage scripts

### Folder Structure

The script assumes a specific folder structure for organizing the files involved in the process:

**origin:**

This folder contains the original JSON file (Localizable.xcstrings) that holds the unfiltered localized strings. This is the source data for the script's filtering operation.
templates:

**templates**
This folder holds multiple .xcstring files, each representing a module or section of the localized strings. These files likely contain strings that are not relevant to the filtering process.

**merged**
The merge folder in the context of the Python script serves as a destination for the filtered JSON file generated after combining multiple .xcstring files. This implies that the script is designed to handle merging multiple .xcstring files and producing a single, consolidated JSON file containing the filtered strings.

## Scripts
### Extract_keys
This Python script, aptly named extract_keys, is designed to streamline the process of managing localized strings within your application. It specifically targets JSON files containing these strings, enabling you to efficiently extract and filter them based on a predefined prefix.

**Purpose and Use Case:**

Imagine you're developing an app and introducing a new feature like a paywall system. This new functionality will require its own set of localized strings for different languages. To ensure proper organization and maintainability, you might create a separate .xcstring file for the paywall module, named paywall.xcstrings for example. The extract_keys script comes into play here.

**How it Works:**

Filtering by Prefix: You define a specific prefix, such as "paywall_". The script then scans the target JSON file (e.g., origin/Localizable.xcstrings) and meticulously extracts all key-value pairs where the key begins with the designated prefix. This ensures you only capture strings relevant to the paywall module.

Generating a New JSON File: Once the script has identified the relevant strings, it creates a new JSON file (often saved in a dedicated folder like merge). This new file will solely contain the filtered strings, making it easier to manage and integrate with your paywall functionality.
