# Project Scratchpad

Last updated: [Date]

## Currently Working On

- Initial project setup

## Open Items

- [ ] Install dependencies (`pip install -r scripts/requirements.txt`)
- [ ] Run first Claude Code session
- [ ] Archive first session

## Known Issues

(None yet)

## Decisions Pending

(None yet)

## Notes

- Project initialized with claude-session-memory-template
- Session memory system ready to use
- Remember to run `./scripts/archive-session.sh` at end of each session

## Quick Reference

### At Session Start
```
User: "Read .claude/STARTUP_PROTOCOL.md and follow startup procedure"
```

### At Session End
```bash
./scripts/archive-session.sh
git commit -m "Session: [description]"
```

### Create Investigation Doc
```
User: "Create investigation doc for [topic] following the template"
```

### Search Past Work
```bash
# Quick search
rg -l "search_term" docs/investigations/

# Semantic search
python scripts/semantic_filter.py "detailed query"
```
