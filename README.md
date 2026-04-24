# gh-scaffold 🚀

A generic GitHub project scaffolding tool. Define your repo, branches, labels, milestones, and issues in a single YAML file — and scaffold an entire GitHub project in one command.

---

## Requirements

- [GitHub CLI](https://cli.github.com) installed and authenticated
- [yq](https://github.com/mikefarah/yq) installed

```bash
# Install GitHub CLI
# Mac
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Install yq
# Mac
brew install yq

# Ubuntu/Debian
sudo apt install yq

# Authenticate GitHub CLI
gh auth login
```

---

## Usage

```bash
chmod +x gh-scaffold.sh
bash gh-scaffold.sh your-project.yaml
```

That's it. The script will:

1. Create the GitHub repository
2. Set up all branches
3. Delete GitHub's default labels and create your own
4. Create all milestones
5. Create all issues assigned to their milestone and labels

---

## YAML Structure

```yaml
repo:
  name: my-project
  description: A short description of the project
  visibility: private  # or public

branches:
  - main
  - develop
  - staging

labels:
  - name: setup
    color: "#0075ca"
    description: Project setup tasks
  - name: frontend
    color: "#d93f0b"
    description: UI related tasks

milestones:
  - title: Milestone 1 - Foundation
    description: Initial setup and configuration
    due_date: "2024-12-31"  # optional
  - title: Milestone 2 - Core Features
    description: Main feature development

issues:
  - title: Create project structure
    body: Set up the initial folder structure and config files.
    milestone: Milestone 1 - Foundation
    labels: [setup]

  - title: Build homepage
    body: Create the main landing page with hero section.
    milestone: Milestone 2 - Core Features
    labels: [frontend]
```

### Fields reference

| Field                      | Required | Description                                          |
| -------------------------- | -------- | ---------------------------------------------------- |
| `repo.name`                | ✅        | Repository name                                      |
| `repo.description`         | ✅        | Short repo description                               |
| `repo.visibility`          | ✅        | `private` or `public`                                |
| `branches`                 | ✅        | List of branch names. `main` is always created first |
| `labels[].name`            | ✅        | Label name                                           |
| `labels[].color`           | ✅        | Hex color code (with `#`)                            |
| `labels[].description`     | ✅        | Short label description                              |
| `milestones[].title`       | ✅        | Milestone title                                      |
| `milestones[].description` | ✅        | Milestone description                                |
| `milestones[].due_date`    | ❌        | Optional due date in `YYYY-MM-DD` format             |
| `issues[].title`           | ✅        | Issue title                                          |
| `issues[].body`            | ✅        | Issue description                                    |
| `issues[].milestone`       | ❌        | Must match a milestone title exactly                 |
| `issues[].labels`          | ❌        | List of label names. Must match defined labels       |

---

## Example

An example YAML config for a full project is included:

```bash
bash gh-scaffold.sh iwc-hub.yaml
```

---

## Output

After running, the script prints direct links to your new repo:

```
============================================================
✅ Project scaffolding complete!

📌 Repo:       https://github.com/username/my-project
📌 Issues:     https://github.com/username/my-project/issues
📌 Milestones: https://github.com/username/my-project/milestones
============================================================
```

---

## Tips

- Keep your YAML files per project. Name them `projectname.yaml` so you always have a record of how the project was set up.
- The script is safe to read — it won't overwrite an existing repo. If a repo already exists, GitHub CLI will throw an error before anything is created.
- Labels are wiped and recreated cleanly. GitHub's default labels (bug, enhancement, etc.) are removed automatically.
- Milestone titles in issues must match **exactly** — including spaces and capitalization.

---

## Files

| File             | Description                                              |
| ---------------- | -------------------------------------------------------- |
| `gh-scaffold.sh` | The main scaffolding script                              |
| `iwc-hub.yaml`   | Example config for the IWC Hub church management project |

---

## License

MIT — use it, modify it, share it freely.