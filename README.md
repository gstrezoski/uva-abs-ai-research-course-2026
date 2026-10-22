# uva-abs-ai-research-course-2026

Course material and planning for a short UvA course that teaches researchers to use agentic AI tools (mainly Claude Code, plus GitHub) in their work. The stated goal is awareness: what the tools can do, where they fail, and how to use them responsibly.

## Layout

| Folder | Contents |
|---|---|
| `slides/` | Lecture and lab decks, with their image assets |
| `reading-materials/` | Lab assignments and facilitator plans |
| `scripts/` | Windows and macOS setup and teardown scripts for participants, a one-page install guide (`setup-guide.pdf`), and the standard `permissions.md` the setup script copies into every lab folder |
| `labs/` | Starter code and data scripts per lab, with facilitator reference solutions |
| `templates/` | Research log and AI-disclosure templates used across labs |
| `meeting-notes/` | One folder per meeting: transcript, notes or summary, mind map |
| `recordings/` | Meeting audio, named `YYYY-MM-DD-<meeting>.m4a`. Git ignores the audio files, so they stay local. |

Meeting folders and recordings use ISO dates (`2026-09-15-all-hands`).

## Course format

- Three evenings: an intro session plus four labs. Wednesday evenings are preferred, and 9–15 November is out (Gjorgji is at ACM Multimedia, Marc is also away).
- Each evening runs 18:15–21:00. The room is booked from 17:30 to 22:00, with sandwiches at 17:30–18:30.
- Dates and room are not confirmed yet. Joaquim is checking with the secretary.

| Day | Session | Leads |
|---|---|---|
| 1 | Intro: Claude Code and GitHub setup, project folder structure | Gjorgji, Joaquim |
| 1 | Lab 1: turn a scientific article into a news piece with a custom `skill.md` | Marleen and her partner (FD) |
| 1 or 2 | Lab 2: privacy and ethics (scraping, AI-disclosure policies, prompt injection, permissions) | Gjorgji, Marc, Bas, maybe Ot |
| 2 | Lab 3: library tool that calls OpenAlex, Semantic Scholar and Scopus | Gjorgji, Marc, Bas |
| 3 | Lab 4: replicate a paper's results by describing the method to Claude | Joaquim, Marleen, Yenan |

Lab 1 material is in `labs/lab1-news-article/`: slides, prompts, the `fd-article` skill and the demo paper.

Lab 2 material is in `reading-materials/Lab2-Privacy-Ethics-Assignment.md` and `slides/Lab2-Privacy-Ethics-Slides.html`. The setup scripts are in `scripts/`.

Lab 4 material (draft) is in `reading-materials/Lab4-Paper-Replication-Assignment.md` and `labs/lab4-replication/`, with an end-to-end capstone example in `reading-materials/`.

## Meeting agendas

### 1. Planning all-hands, 15 September 2026

- **Attendees:** Bas, Marc, Gjorgji, Joaquim, Marleen
- **Format:** in person
- **Files:** [notes](meeting-notes/2026-09-15-all-hands/meeting-notes.pdf), [transcript](meeting-notes/2026-09-15-all-hands/transcript.txt), [mind map](meeting-notes/2026-09-15-all-hands/mind-map.png), recording in `recordings/`

Agenda:

1. Purpose and positioning: awareness over encouragement, colleagues and PhDs rather than students, how to treat university AI policies in the announcement
2. Format and logistics: three evenings, room, power outlets, Wednesday slots outside 9–15 November, registration form platform
3. Tooling and access: GitHub team invites, PowerShell setup script for Windows, Claude Pro seats for three months, small API budget for the library-tool exercise
4. Session content: intro and Labs 1–4, leads for each
5. Recurring themes: logbook and reproducibility habit, skill files and `AGENTS.md`, permission fatigue
6. Open questions: dates, CPD credit hours, Lab 2 on Day 1 or 2, scope of the library tool
7. Action items and owners; reconvene in two weeks with full drafts

### 2. Lab 2 working session (ethics lab), 25 September 2026

- **Attendees:** two participants; the transcript doesn't name the speakers
- **Files:** [summary](meeting-notes/2026-09-25-ethics-lab/summary.txt), [transcript](meeting-notes/2026-09-25-ethics-lab/transcript.txt), [mind map](meeting-notes/2026-09-25-ethics-lab/mind-map.png), recording in `recordings/`

Agenda:

1. Frame Lab 2 as applied ethics, not an AI-safety lecture
2. Scraping contrast: Rijksmuseum API versus WikiArt, `robots.txt` as a social convention, a Google Maps coordinates example
3. Hands-on comparison of Claude-generated scrapers with professional ones
4. Prompt injection demos: hidden reviewer instructions and malicious package READMEs
5. AI-disclosure inventory as a cliffhanger for later sessions
6. Status of the Associate 2.0 project (data collection, privacy rules)

Outcome: the Lab 2 assignment and slides in `reading-materials/` and `slides/`.

### 3. Draft review (planned)

- **Date:** not set. The 15 September meeting said two weeks, which puts it around the end of September.
- **Agenda:** each lab lead presents a full outline, examples and a working exercise. Open items to close:
  - Lab 2 on Day 1 or Day 2, and whether Ot joins
  - Whether the Lab 3 library tool is too much engineering
  - Whether the Lab 4 candidate paper (political bias in LLMs) can be replicated
  - Final dates and room
  - CPD credit recognition
  - Registration form platform

### 4. Course evenings (planned)

Dates to be confirmed. The session content for each evening is in the table above.
