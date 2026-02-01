# Dockerfiles Upgrade Plan - Elixir & Phoenix

**Project**: deer_storage  
**Date**: 2026-02-01  
**Status**: Dockerfiles updated ✅ - Application code updates remaining

---

## Completed Updates ✅

| File | Original | Updated To |
|------|----------|------------|
| **Dockerfile.phoenix** | `bitwalker/alpine-elixir:1.11.0` / `bitwalker/alpine-erlang:23` | `hexpm/elixir:1.18.4-erlang-27.3.4.1-alpine-3.21.3` / `hexpm/erlang:27.3.4.1-alpine-3.21.3` |
| **Dockerfile.nginx-proxy** | `nginx:1.19-alpine` | `nginx:1.27-alpine` |
| **Dockerfile.certbot** | `certbot/certbot:latest` | `certbot/certbot:v3.0.0` |
| **docker-compose.yml** | `postgres:11-alpine` | `postgres:17-alpine` |

---

## New Versions Summary

| Component | Version | Notes |
|-----------|---------|-------|
| **Elixir** | 1.18.4 | Latest stable |
| **Erlang/OTP** | 27.3.4.1 | Compatible with Phoenix 1.8 |
| **Alpine Linux** | 3.21.3 | Latest stable |
| **Nginx** | 1.27 | Latest stable |
| **PostgreSQL** | 17 | Latest stable |
| **Certbot** | 3.0.0 | Pinned for reproducibility |
| **Node.js** | 22.x LTS | Iron LTS (via Alpine packages) |

---

## ARM Architecture Compatibility ✅

The `hexpm/elixir` and `hexpm/erlang` images are **multi-architecture** and support:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64)

**No explicit `--platform` flag needed** - Docker will automatically pull the correct architecture for the server.

---

## Remaining Tasks

### 1. Application Code Updates Required

#### mix.exs Changes:

**Current:**
```elixir
elixir: "~> 1.5",
```

**Should be updated to:**
```elixir
elixir: "~> 1.18",
```

#### Optional Phoenix Upgrade:

**Current:**
```elixir
{:phoenix, "~> 1.6", override: true},
```

**Could be updated to (if desired):**
```elixir
{:phoenix, "~> 1.8", override: true},
```

**Note:** Upgrading to Phoenix 1.8 may require additional code changes for:
- Scopes pattern adoption
- Layout system changes (function components)
- Generator differences

#### Dependencies to Review:

Check for any deprecated dependencies that may need updating for Elixir 1.18 compatibility.

---

## Breaking Changes & Considerations

### Elixir 1.11 → 1.18 Breaking Changes

- Many deprecations removed since 1.11
- `~> 1.5` in mix.exs needs update to `~> 1.18`
- Check deprecated `Mix.Config` usage (should use `Config` module)
- Review any use of deprecated functions in application code

### Node.js/npm Changes

- npm 10.x has different lockfile format
- May need to regenerate `package-lock.json` if build issues occur
- Consider updating `assets/package.json` dependencies

---

## Deployment Checklist

### Pre-Deployment:

- [ ] Update `mix.exs` Elixir version from `~> 1.5` to `~> 1.18`
- [ ] (Optional) Update Phoenix version if desired
- [ ] Review and update any deprecated dependencies
- [ ] Test build locally if possible

### Post-Deployment:

- [ ] Build succeeds on ARM64 architecture
- [ ] Application starts without errors
- [ ] All services (phoenix, nginx, certbot, postgres) communicate properly
- [ ] SSL/certbot functionality works
- [ ] Nginx proxy routes requests correctly
- [ ] Database connections work properly
- [ ] Check application logs for deprecation warnings

---

## Benefits of This Upgrade

- ✅ Modern, maintained base images (hexpm instead of deprecated bitwalker)
- ✅ Native ARM64 support without platform flags
- ✅ Security updates for all components (Alpine 3.10 → 3.21, PostgreSQL 11 → 17)
- ✅ Latest Elixir 1.18 and Erlang/OTP 27 optimizations
- ✅ Compatibility with modern Phoenix features
- ✅ Reproducible builds with pinned versions

---

## Risk Assessment

**Overall Risk**: Low to Medium

- **Docker/Infra**: Low - Updated and ready
- **Application Code**: Medium - May need updates for Elixir 1.18 compatibility
- **Mitigation**: Since project is offline, can fix issues without production impact
