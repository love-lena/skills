---
name: upload-artifact
description: Upload or update Lena's HTML artifacts at artifacts.lena.dog using htmldog, including browser authentication and verification. Use for requests to upload an artifact to lena.dog or replace an existing hosted artifact.
---

# Upload Artifact

Publish to **https://artifacts.lena.dog**, Lena's ShareHTML deployment. In this workflow, “upload to lena.dog” means this artifact service. Use its `htmldog` application client; uploading a document does not require a Cloudflare deployment or infrastructure changes.

## Create or prepare the artifact

If the HTML still needs creating or restyling and `html-artifacts` is installed, use its entrypoint for presentation: Plain by default, Fancy when requested, and the Visual Explainer method for visual teaching. An existing ready-to-upload file needs no style conversion. The upload workflow also works independently of the creation skill.

Use one self-contained HTML file. The shell client sends the file as HTML without converting Markdown, source code, PDFs, or other binaries. Render text sources to HTML when that meets the request; clarify a request for native binary hosting before substituting a format or service.

The hosted viewer supports inline CSS and JavaScript, but blocks network connections, external subresources, native form submission, and nested frames. It runs the artifact without same-origin permission, so browser storage such as localStorage is unavailable. In-page controls can update local UI state; they cannot silently become a persistent or network-backed application. Embed required images, fonts, and media as data URLs, and bundle scripts/styles into the HTML. Keep the editable sources locally. Check the packaged page before uploading, especially interactions that might rely on storage, a local server, or a CDN. If the task requires those capabilities, explain this hosting limitation and keep the working local version available.

## Locate the client and authenticate

1. Look for `htmldog` on `PATH`, then `$HOME/.local/bin/htmldog`. An existing ShareHTML checkout can also supply `bin/htmldog`. If absent, download the supported shell client from [love-lena/sharehtml](https://raw.githubusercontent.com/love-lena/sharehtml/main/bin/htmldog) into the task's `work/htmldog`, check that the download succeeded, inspect it, and run `sh -n` before use. It needs `curl` and `openssl`; it does not need Bun, npm installation, or `cloudflared`.
2. Set `artifact_cli` to the selected script's absolute path. Check its `--help` for command drift. Pin the destination for these commands without changing the user's saved configuration. Repeat these variable bindings in each fresh tool shell; exports do not carry across separate shell calls:

   ```sh
   export HTMLDOG_URL=https://artifacts.lena.dog
   sh "$artifact_cli" config show
   sh "$artifact_cli" list
   ```

   `config show` must resolve to the intended service. `list` is the read-only authentication check; inspect only the metadata needed to resolve the requested document.
3. If the session is missing, expired, or rejected with HTTP 401, run:

   ```sh
   sh "$artifact_cli" login
   ```

   This starts a PKCE-protected device login, prints an authorization URL, and normally opens the browser. Surface that URL and keep the command running while browser authorization completes. Use an existing signed-in browser session where available; leave credential entry and MFA to the user. The CLI polls for up to ten minutes. Use short tool waits so the user can still interact. Treat only `Login complete` followed by a successful `list` as authenticated.

   Sessions last 24 hours. The client stores them in macOS Keychain or Linux Secret Service when available, with a mode-0600 local fallback. Let the client handle credentials; keep tokens, cookies, and credential files out of tool output, artifacts, and the skills repo. GitHub's CLI login and Cloudflare API credentials do not authenticate this application client.
4. Reauthenticate at most once per failed attempt. If login is denied, times out, or still fails, stop and report the required user action. For HTTP 403, check account/document access rather than repeatedly logging in. Report network or service failures as such; they do not establish an expired session.

## Upload or update

Use the existing authorization in the conversation. An explicit request to replace or update an identified artifact authorizes that update; a new confirmation is only needed if the target or requested access is unresolved.

- **New artifact:** `sh "$artifact_cli" deploy "$artifact_file" "$artifact_title"`
- **Existing artifact:** resolve the ID from the supplied `/d/ID` or `/p/ID` URL, or from `list` metadata. Preserve the previous source with `sh "$artifact_cli" pull "$artifact_id" "$backup_file"`, using a new path under `work/revisions/`. Then run `sh "$artifact_cli" update "$artifact_id" "$artifact_file" "$artifact_title"` to retain the URL and existing sharing settings.

Choose the new/update branch from the user's intent. `deploy` creates a new document; it does not find an existing document by filename or prompt to overwrite. These commands differ from the older TypeScript `sharehtml` CLI and its bundled `sharehtml-collaboration` skill.

Capture the returned document ID, URL, and `shareMode`. If a write times out or its outcome is unclear, inspect `list` and pull the candidate source before retrying. A blind second `deploy` can create duplicates. If the result remains ambiguous, report it and stop rather than issuing another write.

## Sharing

New documents on the authenticated service should return `shareMode: private`. An upload request alone keeps them private. Updates preserve their existing access unless the user requests a change; check the response for that mode rather than treating `isShared` as sufficient.

When the user requests sharing, apply their intended audience:

```sh
sh "$artifact_cli" share "$artifact_id" link
sh "$artifact_cli" share "$artifact_id" emails 'person@example.com,other@example.com'
sh "$artifact_cli" unshare "$artifact_id"
```

Choose only the applicable command: `link` enables anonymous read-only access at `/p/ID`; `emails` sets the named collaborators; `unshare` makes the document private. The `emails` list replaces the existing list, so preserve current collaborators when the request is additive. Read them from the viewer's sharing panel before issuing that command; if the current audience cannot be resolved, ask for the complete intended list. A vague sharing request with no clear audience needs clarification; an explicit public-link or named-recipient request does not.

## Verify and deliver

Pull the uploaded source to a separate verification file and compare it with the local upload:

```sh
sh "$artifact_cli" pull "$artifact_id" "$verification_file"
cmp "$artifact_file" "$verification_file"
```

Open the returned viewer URL and check the page and its important interactions. Browser and CLI sessions are separate; complete browser sign-in if necessary. When public sharing was requested, verify `/p/ID` without relying on an authenticated session.

Return the hosted link and its actual access mode. Distinguish successful upload, matching source bytes, and confirmed rendering. If a browser check is blocked, state that limit without retrying a verified upload. Leave the local editable artifact and any prior-version backup available.
