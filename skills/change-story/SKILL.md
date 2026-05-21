---
name: change-story
description: Generate a two-column "change story" walkthrough for a pull request or stack of PRs — a continuous prose chapter that names what changed and why on the left, and a surface-grouped, comprehensive code map on the right. Use whenever the user asks for a PR walkthrough, change narrative, or change story. Especially valuable for stacked PRs or changes of 5+ files where standard diff views fragment the story across pages.
---

# Change Story

A change story is a two-column walkthrough for a code change — a single PR, a stack of PRs, or any diff. The output is a set of markdown artifacts a downstream tool can render as a page with two columns:

- **Left column** — a continuous prose chapter that names the change and tells the reader what to care about.
- **Right column** — a surface-grouped *code map* that covers every hunk in the diff and frames the load-bearing ones with paragraphs of context.

Inline references in the prose ("chips") cross-link into the map; the columns are designed to scroll independently. Even without a renderer, the three markdown files stand on their own as a readable artifact.

Audience: engineers who haven't seen the change. Tone: clear, direct, technical, conversational, **brief**. Assume competence. Don't restate the PR title — any rendering layer already shows it.

## When to use

Use this skill when the user asks for a PR walkthrough, change narrative, or change story.

It earns its keep especially on stacked PRs or changes of 5+ files, where standard diff views fragment the story across pages.

## Inputs you need

Before writing:
1. The change's unified diff (`git diff`, `gh pr diff <id>`, or a saved patch).
2. The PR title, description body, and any linked tickets or commit messages.
3. For a stack: the combined diff across the stack's commits.

The diff is the source of truth. The PR body is evidence, not truth — see "PR body is evidence" below.

## Outputs

Produce three artifacts in the working directory (or wherever the user requests):

- `prose.md` — the continuous chapter that drives the left column.
- `map.md` — the surface-grouped reading guide that drives the right column.
- `diff.patch` — the unified diff, **verbatim**. Do not modify, edit, or curate it. Renderers slice code from this file when expanding hunk rows in the map.

`prose.md` and `map.md` are independently editable; treat them as separate files. **Do not put a `# Prose` or `# Map` H1 inside either file** — the file *is* the column. Inside `prose.md`, use no `##` headings at all. Inside `map.md`, `##` is the group heading.

Each file may begin with an optional YAML-ish frontmatter block (`---` … `---`) holding a snapshot of the change's metadata (`title`, `org`, `repo`, `number`, `sha`, etc.). The frontmatter is informational; renderers are expected to strip it before rendering.

## The one hard rule

**The prose is curated. The map is comprehensive.**

The map must contain **every hunk in the diff** — not a representative selection, not a curated pick. Every hunk. The map is the reviewer's source of truth that nothing's been hidden from them; the prose is what tells them what to *care about*. Hide nothing in the map; frame the load-bearing changes in the prose.

If a renderer surfaces totals (`+N / −N`), they must match the change's header totals. If they disagree, the walkthrough is missing hunks — fix it. Use the **Audit before finishing** checklist at the bottom.

Hunks render uniformly. Every line in the diff — load-bearing or incidental — is reachable from the map; each row in the map is one fence showing `filename:lines  +N −N`. A fence covers a line range and may span multiple `@@` chunks. The map's narrative work happens in **paragraphs between hunks**, not in the hunks themselves: a paragraph above a hunk frames what's coming, a paragraph between two hunks comments on what just appeared, a paragraph at the top of a section sets up the surface. Chips in the prose link to specific hunks.

A 6-PR stack will produce 30–100 hunk rows. The framing paragraphs are what makes them readable — without paragraphs, the map degrades to a flat manifest. Reach for them generously around the load-bearing changes; let incidental hunks (lockfile bumps, generated code, vendored files, mass renames) sit row-only.

**Collapse incidentals at the file level.** A fence's `lines=A-B` can span many `@@` chunks. When every chunk in a file is incidental (the canonical case: a 200-line lockfile churn split across thirty chunks), write **one** fence covering the file's whole touched span (e.g. `lines="1134-2662"`) instead of thirty narrow fences. The audit still passes — coverage is by line, not by fence count — and the map gets one row labelled `uv.lock:1134-2662` that expands to the full churn, rather than thirty rows of noise that bury the load-bearing surfaces. If even one chunk in the file *is* load-bearing, keep that chunk on its own narrow fence (so a chip can land on it precisely) and collapse the rest into a single wide fence around it.

**Fence boundaries close completed statements, not the lines before them.** A fence's `lines=A-B` should end on a line that *completes* a statement or block — never on the column above its closing terminator. The closing `);` of a `CREATE TABLE`, the `}` of a function, the `])` of a multi-line call, the trailing `;` of an assignment: each belongs in the same fence as its opening. The reliable shape is "fence ends on the blank line *after* a finished construct" or "fence ends on the construct's own last line." Concretely, for a 17-line `CREATE TABLE foo (...);` followed by a blank line then a `CREATE INDEX`, the table's fence is `lines="1-17"` (through `);`) or `lines="1-18"` (through the blank line) — never `lines="1-16"` (stopping at the last column, orphaning `);`).

## Generation order: map first, then prose

**Write `map.md` before `prose.md`.** The map is the structural commitment — surface groupings, which hunks are load-bearing, what mechanics deserve a framing paragraph next to the relevant fence. The prose is downstream of those decisions: once the map exists, the prose can *refer* to the map's framing instead of re-explaining the mechanics, and the chip targets are already established.

The failure mode this prevents is the prose absorbing detail that should live next to the code. When the prose is written first, the author hasn't yet decided what the map will explain, so they hedge by explaining everything in the narrative — and the map ends up sparse, the prose ends up dense, and the reader gets the worst of both. Writing the map first forces an explicit answer to "where does this explanation belong?" before the prose pulls it in by default.

Concretely: draft the map's section structure, write framing paragraphs around the load-bearing hunks (algorithmic detail, OR-semantics, ordering invariants, the things that need to sit *next to* the code to make sense), then turn to the prose. With the map in hand, the prose's job becomes naming consequences and pointing chips at the map's framings, not re-deriving them.

## What goes in the prose vs. the map

**The prose names consequences. The map explains mechanics.**

If you find yourself in the prose explaining how a hash is keyed, what each metric tag fires when, how three branches relate to each other, what the field types are, or how a fork resolves OR-semantics — stop. That's the map's job. Frame the relevant hunk in a map paragraph next to it; in the prose, summarize the *consequence* in one sentence and point a chip at the map.

Example of the wrong split — a paragraph that ended up *in the prose* but is mechanics:

*"Three things to notice. First, the hash is keyed on `flag|user_id` — different flags get independent buckets within the same user, so a user in flag A only and a user in flag B only at the same rollout percent land in different sets, and a user enrolled in both flags is enrolled at the OR of the per-flag rates rather than at the rate of any one flag."*

Three sentences walking through the hash's behavior. It belongs in a map paragraph next to the bucketing hunk, where the reader can read it adjacent to the line that does the hashing. The prose version of the same point is one sentence:

*"Each flag enrolls independently against the same user — see [the bucketing block](src/foo.py#L364-L373) for why."*

The prose carries the *what's at stake* (flags enroll independently); the map carries the *how exactly that works* (hash key shape, OR-semantics, multi-flag composition). The reader who only reads prose still understands the consequence. The reader who clicks the chip gets the mechanics, sitting right next to the code.

A useful test before finishing the prose: re-read each paragraph and ask, "could this sentence sit next to a hunk in the map instead?" If yes, move it. The prose should be irreducible — every sentence carries something the map *can't* carry because it's about the change as a whole, not about a specific hunk.

## Prose: writing discipline

The prose is a *technical narrative* — a single piece of writing whose job is to change what the reader thinks, not to convey what's in your head. Most failure modes show up as breaks in the causal chain that runs from a problem the reader cares about to a claim that resolves it. The principles below are checks against those breaks.

**Build the narrative you understand. Don't approximate one you don't.** This rule comes before everything else because narrative form *launders fabrication into apparent understanding* — confident prose that flows causally reads as if the writer knows what happened, even when the causation is invented. Other formats fail loudly when context is missing, but a well-formed narrative can disguise the fact that the writer never actually knew the WHY. Treat the demand for causation as a *demand to gather*: read the diff carefully, look at the surrounding code, read the linked ticket or commit messages, search related conversations. If you can't articulate the causal chain, your job is to find it, not to invent it. When honest gathering doesn't fill the gap, narrow the scope of the prose to what you actually know — a narrower true narrative is always better than a wider invented one. State assumptions explicitly upfront ("assuming the goal here is X, because Y") and reason from them; that's how you stop hedging without inventing. Distinguish hedging from naming the boundary of your knowledge: hedging about ground you've established is performative — strip it; stating what you can't see is accuracy — keep it.

**The PR body is evidence, not ground truth.** When the body mentions something not visible in the diff — a sibling PR, a downstream consumer, a constant named in application code, a rejected tradeoff — either quote the body explicitly ("the body says…", "per the PR description…"), write `[NEEDS INFO: <what's missing>]`, or strip the sentence. Don't adopt body-only claims as fact. The diff is what the reader can verify by clicking through; the body's claims must themselves be checked against the diff.

**Open with the reader's problem, not background.** This is where most change narratives die. The default move is to give context first ("we've been working on X for the last few weeks…") and the reader, who is searching for what matters, slows down looking for the thing that matters. Locate a problem the reader cares about *first*; let the background fall in around it. The diagnostic words that signal tension — *but, however, although, inconsistent, unexpected, surprising, anomaly, unresolved* — should appear early. A useful editing move: write the opening last, after you know your claim, so the situation demonstrably sets up the claim instead of meandering toward it.

**Lead with the conclusion when the reader is an answer-seeker.** Engineers reading a change story want the answer, not the path you took to get there. The thinking-order — explore, diagnose, refine, conclude — is correct for *writing*; it's wrong for *reading*. Invert. The first sentence (or first two) should carry the claim; the rest of the prose constructs the case for it. This combines naturally with opening with the reader's problem: the first sentence locates the problem and states the resolution, and the rest fills in the why. Test: if a reader read only your opening, would they know what's at stake and where you're headed?

**Earn the read with brevity.** The reader doesn't *need* to read the prose — the map is the comprehensive source of truth, and chips link directly to mechanics. They read the prose only if it earns the read, and brevity is most of what earns it. A one-paragraph narrative that names the load-bearing claim and points chips at the map is the **default shape**, not the floor. It is fine — expected — for unimportant context to be missing; assume the reader will click into the map for anything they want to know more about. The instinct to be thorough is the wrong instinct here; the instinct to cut is the right one. If you can say it in one paragraph, do. If a sentence isn't load-bearing, it isn't earning its place — strip it. The reader's time is the scarce resource; protect it ruthlessly.

**Build a causal spine.** A narrative is a series of sentences where each one impacts the next. Without that, you have a list. Read the draft sentence by sentence and ask whether each follows from the previous and leads into the next. Connectives like *but then, because of that, so now, as a result, which meant that, this left us with* are the visible markers of causal flow. Their absence across a whole paragraph usually means you've written a list with sentence breaks. The pattern to avoid is "and… and… and…" — facts placed beside each other without connection.

**Diagnose, don't dump.** Numbers and facts without interpretation are raw material — the reader can read those on their own. Your value is in telling them what the facts mean. "The handler now uses Redis" is a fact; "The handler now uses Redis, so the rate limit is shared across edge nodes — the failure mode under load shifted from per-node to centralized" is a diagnosis. The same applies to qualitative facts: "uses Postgres" is a fact; "uses Postgres, which limits us when we need cross-region reads" is a diagnosis. Whenever you state a fact, ask whether you've also said what to make of it.

**Trade-offs only when documented.** If the PR description, a commit message, a linked doc, or a code comment names a choice and what it cost, surface it — that's load-bearing. Otherwise, don't manufacture one. Accept that you might not have the full picture: you can't know what alternatives the team considered or others actually weighed, only what you have insight into.

**Honor reader expectations at the sentence level.** Old or familiar information at the *start* of a sentence; new or important information at the *end* (the stress position); subject and verb close together. When a sentence feels heavy and you can't say why, check these three first.

**Self-check before finishing.** Did I assert a causal link I can't defend? Did I rely on an assumption I never declared? Did I claim something the PR body asserted but the diff doesn't show? (If yes, either quote the body or write `[NEEDS INFO: …]` inline.) Did I open with background instead of the reader's problem? If a reader read only my opening, would they know what's at stake and where I'm headed? Did I list facts without causal connectives — am I in "and… and… and…" mode? Did I dump numbers or diff stats without diagnosing them? Am I explaining when I should be arguing? Did I hedge about ground I've actually established? Did I explain mechanics that belong in the map? (If yes, move them: frame the relevant hunk in a map paragraph and replace the prose explanation with a one-sentence consequence + a chip.) Is each paragraph one claim, ~60–100 words? Over 120 means you're elaborating — strip or move to the map. Two claims fused with a "related X" transition? Split or drop one. A draft that fails most of these usually means the underlying thinking isn't ready — gather more from the diff and the change's context; don't paper over.

## Prose: rendering mechanics

- One continuous chapter. **No `##` or `###` headings inside `prose.md`.** If you reach for one, write a paragraph break instead.
- **Paragraphs are short. One claim each, roughly 60–100 words.** Past ~120 you're elaborating instead of stating — strip hedges and meta-framing, or move the detail to a map paragraph next to the hunk. Most changes land at 1–3 paragraphs; a stack with several load-bearing surfaces might reach 4–5; beyond that is almost always padding. If you have a second distinct claim, give it its own paragraph — don't glue it onto the first with a "related X" transition. Padding to feel thorough is a smell. Restating the diff in prose is a smell. The hard test: re-read each paragraph and ask "could this sit next to a hunk in the map instead?" — if yes, move it there and replace the prose with a one-sentence consequence + a chip.
- **Chips** reference hunks via path + line range. The path is relative to the repo root; the fragment is `#L<a>-L<b>` (or `#L<a>` for a single line). A renderer should match the chip's path against a fence's `path=` and the chip's range against the fence's `lines=` (must fall inside).
  - `[label](src/foo.ts#L7-L13)` — points at lines 7–13 of a fence whose `path="src/foo.ts"` covers them.
  - `[label](src/foo.ts)` — no fragment. Matches the first fence on that path; claims the whole hunk.
- The natural noun phrase is the chip text — usually a symbol name, file name, or short label. Examples:
  - `[SandboxReq](src/schemas.py#L1-L12)` — symbol → schema hunk
  - `[the rewritten aggregation](src/agg.py#L31-L48)` — descriptive phrase → load-bearing range
  - `[404s rather than 403s](src/handler.py#L8-L9)` — the literal interesting two lines
- Inline diff peeks (sparingly!) — a fenced diff inside the prose itself, when a chip alone wouldn't carry the point:

  ````
  ```diff filename=schemas.py caption="SandboxReq — prompt + model + system + temperature"
  + class SandboxReq(BaseModel):
  +     prompt: str
  +     model: str
  ```
  ````

  Peeks aren't chip targets (no `path=`/`lines=`), so reach for them rarely.
- **No blockquotes.** `> …` and `> NOTE: …` are not allowed in the prose. The prose is one continuous chapter of normal paragraphs; an italic aside with a left bar fragments the reading and signals "I couldn't fit this into the argument." If the content matters, work it into a sentence. If it doesn't, drop it.

## Map: structure and mechanics

The map is a *reading guide* to the code. Block kinds:

- **`## Group title`** — a surface-based group. Pick groupings that match how a reviewer thinks (`Backend surface`, `Route plumbing & flags`, `Tester UI`, `History`, `Batch`). **Do not group by PR number** unless the PRs *are* the surfaces; PR boundaries are an accident of how the work was packaged.
- **Paragraphs** — frame what's in the group, what's worth attention, and how to read the hunks below. **Most framing should be in paragraphs**, not notes.
- **`### Sub-head`** — chunking inside a long group. Use to break up >5 hunks into smaller readings (`Form`, `Results — v1`, `Results — v2`, `Plumbing`).
- **No blockquotes.** `> …` and `> NOTE: …` are not allowed in the map. Whatever you'd put in a note belongs in a paragraph between hunk cards — paragraphs can sit anywhere in the map, including between two hunks.
- **Hunk cards** — fenced `diff` blocks with attributes. **The body is left empty** — a renderer slices the right lines from `diff.patch` and renders them. The attribute set:

  ````
  ```diff path="src/foo.ts" lines="1-12" expanded
  ```
  ````

  | attr | required | meaning |
  |---|---|---|
  | `path=` | yes | path to the new file in the diff. Must match a `+++ b/<path>` (or `diff --git a/X b/<path>`) line. |
  | `lines=A-B` | yes | new-file line range (1-indexed, inclusive) the fence covers. A renderer slices every `@@` chunk in the diff that overlaps `[A, B]` and renders them in order. Single-line hunks: `lines="42-42"`. Chips matching against this fence must fall inside `[A, B]`. |
  | `expanded` | optional flag | start the hunk expanded (full diff visible at first paint instead of collapsed-to-row). Reserve for the one or two hunks the reader should land on already opened. |
  | `caption="…"` | optional | label for inline peeks in the prose. |

  - **Bodies stay empty.** Renderers slice code from `diff.patch` — don't paste diff lines into the fence. (Inline peeks in the prose are the one exception: those take a verbatim body since they aren't chip targets.)
  - **`lines=` is required**, even for single-line hunks (`lines="42-42"`). Without it the renderer may skip the fence entirely.
  - **No descriptive attributes on the fence.** Frame the hunk in a paragraph above (or between) the relevant fences instead.

## A short example

`prose.md`:

```markdown
Three PRs landing together: a per-token rate limiter at the edge. The contract for everything else lives in [a flat `BucketState`](src/limit/token_bucket.ts#L1-L7) any caller can persist. The single trick of the file is that `refill` is pure — it [advances the clock without taking tokens](src/limit/token_bucket.ts#L9-L13), so every caller asks the same question.

The middleware itself is small ([the entrypoint](src/server.ts#L20-L24)); the order of [auth before rate-limit](src/server.ts#L21-L22) matters because the limiter keys on the verified token, not on attacker-controlled input.

PR #3 is the dangerous one. The in-process `Map` becomes a [Redis-backed store](src/limit/redis_store.ts#L1-L40), and the bucket math runs in a [Lua script so the read-modify-write is atomic](src/limit/redis_store.ts#L8-L13). We duplicate the math on purpose — if you change one, you change both.
```

`map.md`:

````markdown
## Bucket primitive

Plain data and a single pure function. Two flat records — no class, no hidden state — so anyone can persist a `BucketState` to Redis or a row in Postgres without ceremony. `refill` is pure: it advances the clock without taking tokens, so every caller asks the same question.

```diff path="src/limit/token_bucket.ts" lines="1-7"
```

```diff path="src/limit/token_bucket.ts" lines="9-13"
```

## Middleware

Order matters here: `auth` runs before `rateLimit` so the limiter sees a verified token, not whatever the client sent.

```diff path="src/server.ts" lines="20-24"
```

## Redis-backed store

The load-bearing one. Atomicity lives in a Lua script that reads state, refills against the clock, and atomically takes or returns 0. The math is duplicated from `token_bucket.ts` on purpose — if you change the algorithm, change both.

```diff path="src/limit/redis_store.ts" lines="1-40" expanded
```
````

## Authoring discipline (consolidated)

- **Total prose budget: ≤120 words for a typical single-PR change story, ≤180 for a stack or genuinely complex change.** Past that and you're writing more than the map needs you to. Most changes land at 1–2 paragraphs of 60–90 words each, NOT 3. A small bugfix or a clean refactor can be a single paragraph under 80 words and still tell the whole story; reach for a second paragraph only when the change has a genuinely separate load-bearing concern (a security envelope, a non-obvious error contract, an architectural inversion). Three paragraphs is a smell, not a target. The reader doesn't have to read the prose — the map is the source of truth — so brevity is what makes them *want to*. Cut hard. If you're not sure whether a sentence earns its place, it doesn't.
- **Write the map first.** The map is the structural commitment; the prose is downstream of it. Drafting prose first leads to dense narratives that absorb the mechanical detail (hash semantics, branch ordering, type shapes) the reader is better served reading next to the relevant hunk.
- **Mechanics in the map, consequences in the prose.** If a sentence in the prose explains how something works at the code level — hash key shape, OR-semantics across cases, what each branch does — move it into a map paragraph next to the relevant hunk. The prose names what's at stake; the map's framing paragraphs make the mechanics legible to a reviewer reading the code.
- **Comprehensive map, curated prose.** Every hunk in the diff appears in the map. The load-bearing ones get a framing paragraph above (or between) the fences; everything else is a row-only entry. Run the **Audit before finishing** below before saving.
- **One fence per file for all-incidental churn.** Coverage is computed by line, not by fence count — so a lockfile whose every chunk is a routine version bump should be one fence with a wide `lines=A-B` covering the whole touched span, not thirty narrow fences.
- **Group the map by *surface*, not by PR.** The point is to put v1 and v2 of the same component next to each other.
- **Write the prose as a single chapter.** No inner headers. No transitions like "now, with that done…" — those are the smell of a structural element that doesn't belong.
- **Frame load-bearing hunks in paragraphs.** A reader should be able to skim only the paragraphs in the map and understand the shape of the change.
- **Prefer line-range chips for "the four interesting lines."** When you find yourself writing "see lines 31–48 of the rewrite," wire it as `[label](src/path/to/file.ts#L31-L48)` and let the reader click into the highlight.
- **Reserve `expanded` for one or two hunks.** Default-expanded means *this is the hunk you came here to read*.
- **No blockquotes anywhere.** Neither prose nor map renders italic asides — both columns demote any `> …` to a regular paragraph. If the content matters, work it into a sentence; if it doesn't, drop it.
- **Don't add a top-level `# Title`** to either file. Any rendering layer presents the change's header.
- **Don't add a "Summary" section.** The reader just read the chapter.

## Audit before finishing

This is the structural check to run before you save. The aim is comprehensiveness without re-curating: anything the audit surfaces gets added as a bare fence, not a new framing paragraph.

Walk `diff.patch` top-to-bottom. For each `@@ -x,y +a,b @@` block:

1. **Identify the path.** It's the most recent `+++ b/<path>` line above the block. Skip the block if the path is `/dev/null` (pure deletion).
2. **Compute the new-file extent.** The block covers new-file lines `[a, a + b − 1]`. (If `,b` is omitted, treat `b = 1`.)
3. **Cover every `+` line.** Coverage is by line, not by fence count. Every `+` line inside the block must fall inside some `diff` fence in `map.md` on the same `path=` — one wide fence, several narrow fences whose ranges add up, or any mix. Context (` `) lines around the `@@` block don't need coverage; they're scaffolding renderers can synthesize. When you break a hunk into multiple fences, snap the boundaries to blank lines or natural section breaks (between SQL statements, between functions, between import groups) — never mid-statement, never before a closing `)`/`}`/`;` that completes the line above. If a `+` line falls outside every fence, widen the nearest one. If a block has no fence at all, add a bare fence — no framing paragraph, no chip target needed; incidental hunks (lockfiles, generated code, vendored files, mass renames) belong in the map as row-only entries with one fence covering the whole touched span.
4. **Tally the block.** Inside the block (between this `@@` line and the next `@@` line, or the end of the diff), count lines beginning with `+` as additions and lines beginning with `-` as deletions.

When you've walked every block, sum all additions and all deletions across the diff. They must equal the change's `additions` / `deletions`. If your sum is short, a block is missing or a fence's `lines=` doesn't span its full extent — add or widen the fence. If your sum overshoots, you've got duplicate or overlapping fences — collapse them.
