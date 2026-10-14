# ToolPouch policy pages

The privacy, support, and terms pages contain English and Polish translations.
Each public URL has its own directory and `index.html`:

- `/policies/toolpouch/privacy`
- `/policies/toolpouch/support`
- `/policies/toolpouch/terms`

## Deployment

Deploy this directory to `public/policies/toolpouch` on the web server:

```text
public/
└── policies/
    └── toolpouch/
        ├── privacy/
        │   └── index.html
        ├── support/
        │   └── index.html
        └── terms/
            └── index.html
```

Each page selects its document from the URL; no server-side rewrite rules are
required. The language switch works without reloading the page.

Application links are configured in `toolpouch/Resources/ApplicationLinks.json`.
