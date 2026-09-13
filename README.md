# dotfiles

Personal macOS config, kept here so a second machine can pick up the same setup.

These are copied into place by hand — there is no install script, so nothing runs
against your machine without you asking for it.

## Contents

| Path | Copy to | What it is |
| --- | --- | --- |
| `ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal: SFMono Nerd Font, Catppuccin Mocha, block cursor, copy-on-select |
| `nvim/` | `~/.config/nvim/` | Neovim config, based on the LazyVim starter |
| `gradle/init.d/eclipse-extra-configs.gradle` | `~/.gradle/init.d/` | Makes custom Gradle configurations visible to `jdtls` |
| `zsh/.zshrc` | `~/.zshrc` | oh-my-zsh + powerlevel10k, aliases, sdkman/nvm/bun setup |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Claude Code status line: model, context %, session cost, 5h rate-limit bar, folder + git state |

## Installing

```sh
mkdir -p ~/.config/ghostty ~/.gradle/init.d ~/.claude
cp ghostty/config                             ~/.config/ghostty/config
cp -R nvim/                                   ~/.config/nvim/
cp gradle/init.d/eclipse-extra-configs.gradle ~/.gradle/init.d/
cp zsh/.zshrc                                 ~/.zshrc
cp claude/statusline-command.sh               ~/.claude/statusline-command.sh
```

Back up anything already at those paths first — `cp` overwrites.

### Dependencies

`zsh/.zshrc` expects these to exist; it will start with pieces missing, but with errors:

- [oh-my-zsh](https://ohmyz.sh) with the [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
- The `zsh-autosuggestions` plugin, plus `zsh-syntax-highlighting` and
  `zsh-history-substring-search` from Homebrew
- [sdkman](https://sdkman.io), [nvm](https://github.com/nvm-sh/nvm), and [bun](https://bun.sh) if you
  want the Java/Node/Bun paths to resolve

`nvim/` bootstraps itself on first launch — LazyVim installs its own plugins, and
`lazy-lock.json` is committed so you get the same plugin versions on both machines.

## The Gradle init script

Gradle's eclipse model builds its classpath from `eclipse.classpath.plusConfigurations`.
A build that wires a custom configuration onto a source set, e.g.

```groovy
sourceSets { main.compileClasspath += configurations.flinkShadowJar }
```

only mutates that source set's `FileCollection`, which the eclipse model never reads. So
`jdtls` resolves a classpath missing those dependencies and every import from them shows as
unresolved — while IntelliJ, which reads the source sets directly, is fine. The script adds
resolvable `flinkShadowJar` / `shadow` / `provided` configurations back onto the eclipse
classpath.

It only touches the eclipse model, and only when the eclipse plugin is applied — which is
something Buildship does for itself. Normal `./gradlew` builds are unaffected.

## The Claude Code status line

Copying the script is not enough — Claude Code only calls it if `~/.claude/settings.json`
points at it:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

It reads the session JSON Claude Code writes to stdin and prints two lines: model, context
percentage with token counts, session cost, and a 5h rate-limit bar on the first; repo
folder, git branch with staged/modified counts, and the worktree name when one is active on
the second. Context and rate-limit numbers turn yellow then red as they climb.

`jq` is required (`brew install jq`) — without it every field comes out empty. The rest is
POSIX shell, so no Node or Bash-only features.

## Not included

Machine- and work-specific files are deliberately left out: shell environment holding
employer identifiers (`~/.zshenv`), git identity (`~/.gitconfig`), and
`~/.zprofile` / `~/.profile`, which Docker Desktop and JetBrains Toolbox rewrite on their own.

`~/.claude/settings.json` is also left out — it names private plugin marketplaces — so only
the `statusLine` block above needs recreating there.

`zsh/.zshrc` keeps its corporate-certificate line, guarded so it does nothing when the file
is absent.
