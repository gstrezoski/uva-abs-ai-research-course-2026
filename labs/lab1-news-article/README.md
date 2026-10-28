# Lab 1: turn a paper into a newspaper article

Evening 1, 21 October 2026. Marleen de Jonge.

One task, done at four levels of the AI ladder: a single prompt in a chat, a chat with a skill,
an agent working in your own folder, and a team of agents. The article is the vehicle; the method
you can run again is the point.

| File | For |
|---|---|
| `slides/lab1-slides-handout.pdf` | The deck with every slide in its final state, for reading afterwards |
| `slides/lab1-slides-presentation.pdf` | The deck as presented, with click-by-click builds and clickable prompt boxes |
| `paper/paper.pdf` | The demo paper: Tabachová, Diem, Borsos, Burger and Thurner (2024), "Estimating the impact of supply chain network contagion on financial stability", *Journal of Financial Stability* 75, 101336. Open access, CC BY 4.0 |
| `prompts/1-write-the-article-chat.md` | Level 0: one prompt in a Claude chat. Attach your paper and three example articles |
| `prompts/2-build-your-own-skill-chat.md` | Level 1: Claude asks you a few questions, then writes a `SKILL.md` with an interview and a fact check |
| `prompts/3-agent-in-your-folder-claude-code.md` | Level 2: Claude Code scans ten US banks' 10-K filings on SEC EDGAR for supply chain risk. Put your own name and email in the request header |
| `skills/fd-article/SKILL.md` | The skill shown in the session: interviews you one question at a time, drafts in FT or FD style, then checks every number and claim against the paper |
| `skills/fd-article.zip` | The same skill, ready to upload |

## Example articles

The prompts ask for three example articles from the newspaper you write for. They are not in this
repository because they are behind a paywall. Pick three news reports that discuss a research finding,
through your own subscription or the UvA library, or use the copies shared on the course OneDrive.

## Using the skill

In Claude: Customize → Skills → + → Upload a skill → choose `fd-article.zip`. Start a new chat,
attach a paper and type "Use the fd-article skill to turn this paper into an FT article", or type
`/fd-article`. Open `SKILL.md` in any text editor to adapt it.
