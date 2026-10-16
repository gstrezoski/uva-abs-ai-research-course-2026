# Lab 4, evening 3: replicating a classic with AI assistants

Joaquim's 60-minute part of Lab 4: five minutes on optimization with agents, then Card and Krueger (1994) as a hands-on replication with Claude Code.

| File | What it is |
|---|---|
| `ck_session.pdf` | The slide deck, ready to present or share with participants (links and prompts can be copied from it) |
| `ck_session.tex` | Beamer source. Speaker notes are in `\note{}`; uncomment the `\setbeameroption` line to show them on a second screen |
| `ck_explainer.pdf` | Example explainer deck made by an assistant; two of its pages appear on the slide "An assistant explains the paper" |
| `ck_podcast_1min.mp3` | One-minute podcast (58.5 s) synthesized with the Windows built-in voices (Zira as host, David as economist) |
| `ck_podcast_1min.md` | The script of that podcast |
| `demo-run/` | The dry run behind the Checkpoint and timeline slides: a fresh agent given only the Round 1 prompt. Its script, its printed output and its own step-by-step log |
| `demo-notebook/` | The notebook demo on the book slide: a fresh agent ran MO-book notebook 01/02 and a what-if (demand cap on U from 40 to 60). Its comparison and log |
| `advanced/` | Optional cards F and G: `ck_table5_iv.py` reproduces Table 5 and the IV test of the first-difference model; `table5_iv_results.txt` is its output. Run: `python -I advanced/ck_table5_iv.py <path/to/public.dat>` |
| `figures/` | Kings maps (made by Codex from saved solutions) and the UvA logo files |

## Build

```
pdflatex ck_session.tex
pdflatex ck_session.tex
```

Needs a LaTeX distribution with the metropolis Beamer theme, `fontawesome5` and `ulem`. Run from this folder: the deck reads `ck_explainer.pdf` and `figures/`.

## Sources and notes

- Paper: https://davidcard.berkeley.edu/papers/min-wage-ff-nj.pdf
- Data and the authors' SAS program: https://davidcard.berkeley.edu/data_sets/njmin.zip
- Kings benchmark: Máximo, Cordeau and Nascimento (2025), https://doi.org/10.1111/itor.13387, code at https://github.com/vinymax10/AILS-MCLP
- The Kings maps build on Fleur's notebooks and Parvathy's thesis work; confirm how they want to be credited before presenting.
- The dry run was a Claude Code subagent told where Python is installed and on which PDF page Table 4 is. It is one run, not a benchmark.
- Not yet tested: whether the optional audio prompt produces a two-voice file on a Mac.
