# Unstructured technical documentation

This repository hosts the public documentation source content for: 

* [The Unstructured user interface](https://docs.unstructured.io/ui/overview)
* [The Unstructured API](https://docs.unstructured.io/api-reference/overview)
* [Unstructured for Business](https://docs.unstructured.io/business/overview)
* [The Unstructured open source library](https://docs.unstructured.io/open-source/introduction/overview)

## Contributing to the documentation

Everyone is welcome to contribute, and you can do it in a couple of ways:

* See something wrong with the existing documentation? Need a new example/tutorial? [Submit an issue](https://github.com/Unstructured-IO/docs/issues).
* Improve the docs by creating a pull request (see the next section).

### Creating a pull request

To contribute changes to the documentation by creating a pull request:

1. If you're not a member of the internal Unstructured documentation team, start by [forking this repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo). If you are part of the internal Unstructured documentation team, you can [clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) instead. 
2. Create a new branch with a descriptive name. 
3. Add your changes.
4. Check for grammatical and technical correctness of the changes. 
5. Ideally, you should preview your changes locally (see the next section).
6. Create a pull request.
7. Add [Paul-Cornell](https://github.com/Paul-Cornell) and [ajaykrish-uns](https://github.com/ajaykrish-uns) to your pull request's list of reviewers. They will be automatically notified to review it. One of them will review your pull request. Once the pull request is final and approved, they will merge and publish your contribution!

### Previewing documentation changes locally

Before creating a pull request, you should check to make sure your changes are built and displayed correctly locally. 

1. Install node.js: `brew install node`
2. Install mintlify: `npm i -g mintlify`
3. Navigate to the `docs` directory (where the `mint.json` file is located) and run: `mint dev`. Local preview should be available at `http://localhost:3000`.

