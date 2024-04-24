# Documentation for Unstructured products

This repo hosts documentation for: 

* [Unstructured Open Source Library](https://github.com/Unstructured-IO/unstructured) 
* [Unstructured APIs](https://unstructured.io/api-key-hosted)
* [Unstructured Enterprise platform](https://unstructured.io/platform)

## Contributing to the documentation

Everyone is welcome to contribute, and you can do it in a couple of ways:

* See something wrong with the existing documentation? Need a new example/tutorial? Submit a [GitHub Issue](https://github.com/huggingface/cookbook/issues).
* Improve the docs by opening a pull request. 

### Creating a pull request

To contribute changes to the documentation:

1. Create a new branch with a descriptive name.
2. Add your changes. DO NOT MANUALLY EDIT THE CONTENTS OF THE SNIPPETS FOLDER. These are auto-generated from tested code examples. 
3. Check for grammatical and technical correctness of the changes. 
4. Preview your changes locally. [See how below](#previewing-documentation-changes-locally). 
5. Create a pull request.
6. Ping [MKhalusova](https://github.com/mkhalusova) for a review.

### Previewing documentation changes locally

Before creating a pull request, make sure your changes are built and displayed correctly locally. 

1. Install node.js: `brew install node`
2. Install mintlify: `npm i -g mintlify`
3. Navigate to the docs directory (where the `mint.json` file is located) and run: `mintlify dev`. Local preview should be available at `http://localhost:3000`.

