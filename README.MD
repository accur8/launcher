

Can be built with the most recent haxe version 4.2.5 also was working with 4.0.5



# Docker

## Authenticate to GitHub
- [Create new personal access token](https://github.com/settings/tokens/new?scopes=write:packages,delete:packages)
    - The `write:packages` and `delete:packages` scopes should be automatically selected
- Run `docker login ghcr.io`
    - Specify your GitHub username
    - Use the personal access token as your password

## Publish docker image
- Authenticate if you haven't already (see above)
```bash
nix-shell --command "haxe build.hxml"
docker build -t ghcr.io/accur8/a8-launcher .
docker push ghcr.io/accur8/a8-launcher
```
