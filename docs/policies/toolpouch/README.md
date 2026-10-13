# ToolPouch — publikacja dokumentów

Każdy publiczny adres ma własny katalog z plikiem `index.html`. Wszystkie trzy pliki zawierają dwujęzyczne wersje dokumentów i automatycznie wybierają właściwy widok na podstawie adresu URL:

- `/policies/toolpouch/privacy`
- `/policies/toolpouch/support`
- `/policies/toolpouch/terms`

## Pliki na serwerze

Skopiuj zawartość katalogu `toolpouch` do `public/policies/toolpouch` na serwerze. Docelowa struktura:

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

Nie są potrzebne reguły przekierowań nginx ani Apache. Po publikacji każdy z trzech adresów powinien zwracać kod `200`, zachowywać swój czytelny URL i pokazywać właściwy dokument. Przełączniki PL/EN działają bez przeładowania strony.

## Kontrola przed publikacją

- Potwierdź, że `support@ioxtec.com` odbiera wiadomości.
- Potwierdź, że `IOXTEC` jest właściwą nazwą wydawcy widoczną dla użytkownika.
- Jeżeli wydawcą jest osoba fizyczna, uzupełnij dokumenty o jej właściwą nazwę prawną i wymagane dane kontaktowe.
- Nie dodawaj do tej strony analityki ani zewnętrznych zasobów bez ponownej aktualizacji polityki prywatności.
