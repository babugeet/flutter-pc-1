# Formwell

Standalone HTML, CSS, and JavaScript fitness tracker frontend.

## Structure

- `pages/auth.html` contains login and signup.
- `pages/app-shell.html` contains shared signed-in navigation and header.
- `pages/dashboard.html`, `pages/workouts.html`, `pages/stats.html`,
  `pages/reports.html`, and `pages/profile.html` contain their screen markup.
- `pages/chat.html` is a visual-only chat preview; no AI service is connected.
- `styles/base.css` and `styles/layout.css` contain shared styling.
- `styles/auth.css`, `styles/dashboard.css`, `styles/workouts.css`, and
  `styles/stats.css`, `styles/reports.css`, `styles/profile.css`, and
  `styles/chat.css` contain feature styling.
- `styles/responsive.css` contains responsive layout rules.
- `app.js` handles template loading, navigation, authentication, and API calls.

## Run locally

Start the API and PostgreSQL database using the instructions in the sibling
`backend-fitness` repository, then serve this directory:

```sh
python3 -m http.server 8081
```

Open `http://localhost:8081`. The frontend calls the API at
`http://localhost:8080` by default. To use another API URL, add it as the `api`
query parameter, for example `?api=http://localhost:9000`.
