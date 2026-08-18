With the `hugo.work` file handling the local heavy lifting, your workflow is now neatly divided into three distinct phases: Local Prototyping, Pushing the Module, and Updating the Blog.

Here is the exact step-by-step workflow for modifying your shared components and getting those changes into production.

### Phase 1: Local Prototyping (The Fast Loop)

Because of your workspace file, you do not need to touch Git while you are actively writing code or tweaking CSS.

1. **Start the Server:** Open a terminal in `~/projects/personal/sydneytech-blog` and run `hugo server -D`.
2. **Edit the Module:** Open your code editor and make changes directly to the files inside `~/projects/personal/hugo-shared`.
3. **Live Test:** Every time you save a file in `hugo-shared`, the server running in `sydneytech-blog` will detect it and hot-reload your browser. Iterate here until the feature looks and works exactly how you want.

### Phase 2: Committing the Shared Code

Once you are happy with the changes, you need to lock them into the remote `hugo-shared` repository so Cloudflare can eventually see them.

1. **Navigate to the Shared Repo:**
```bash
cd ~/projects/personal/hugo-shared

```


2. **Commit and Push:**
```bash
git add .
git commit -m "feat: updated media shortcodes and css"
git push origin main

```



*Note: Pushing this repo does **not** trigger a Cloudflare deployment for your blogs. Cloudflare only builds when the blog repositories themselves receive a push.*

### Phase 3: Pushing the Update to Production

Right now, Cloudflare Pages is still pointing to the *old* version of your module because the `go.mod` and `go.sum` files inside `sydneytech-blog` haven't been updated. You need to tell your blog to fetch the latest commit you just pushed.

1. **Navigate back to the Blog:**
```bash
cd ~/projects/personal/sydneytech-blog

```


2. **Update the Module Tracking:** Run this command to tell Hugo to reach out to GitHub and pull the latest version of your shared repository:
```bash
hugo mod get -u

```


*This will update your `go.mod` and `go.sum` files with the new cryptographic hashes and commit timestamps.*
3. **Commit and Deploy:** Commit those updated tracking files to the blog's repository and push.
```bash
git add go.mod go.sum
git commit -m "chore: bump hugo-shared module to latest"
git push origin main

```



As soon as that push hits GitHub, Cloudflare Pages will spin up, read the updated `go.mod`, download the fresh code from your `hugo-shared` repository, and deploy the new features to `www.sydneytech.org`.

### The Multi-Blog Advantage

When you eventually bring `benburke.org` and `leonardkoan.net` online, they will benefit massively from this. You do Phase 1 and Phase 2 exactly once. Then, for Phase 3, you just run `hugo mod get -u` inside each blog's respective directory whenever you want them to inherit the new shared features.
