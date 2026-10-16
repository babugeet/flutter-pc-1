const API_BASE =
  new URLSearchParams(window.location.search).get("api") ||
  "http://localhost:8080";
const appRoot = document.querySelector("#app-root");
const workoutLabels = {
  legpress: "Leg Press",
  squats: "Squats",
  weightlift: "Weight Lift",
  deadlift: "Dead Lift",
  pushups: "Push Ups",
  pullups: "Pull Ups",
  jumpingjacks: "Jumping Jacks",
  jacks: "Jumping Jacks",
  walking: "Walking",
  swimming: "Swimming",
  cycling: "Cycling",
  running: "Running",
  lunges: "Lunges",
  benchpress: "Bench Press",
};

let profileData = null;
let planCache = null;
let viewLoadId = 0;

function localDateString(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function username() {
  return localStorage.getItem("fitness_username") || "";
}

async function loadTemplate(name) {
  const response = await fetch(`pages/${name}.html`);
  if (!response.ok) throw new Error(`Could not load ${name} screen.`);
  return response.text();
}

async function showAuth(
  mode = "login",
  { username: savedUsername = "", message = "" } = {},
) {
  appRoot.innerHTML = await loadTemplate("auth");
  appRoot.querySelector("#login-panel").hidden = mode !== "login";
  appRoot.querySelector("#signup-panel").hidden = mode !== "signup";
  if (savedUsername) {
    appRoot.querySelector('#login-form [name="username"]').value =
      savedUsername;
  }
  if (message) {
    setMessage(appRoot.querySelector("#login-message"), message, true);
  }
}

async function showApp() {
  appRoot.innerHTML = await loadTemplate("app-shell");
  const currentUsername = username() || "Athlete";
  appRoot.querySelector("#side-username").textContent = currentUsername;
  appRoot.querySelector("#side-avatar").textContent = currentUsername
    .slice(0, 1)
    .toUpperCase();
  appRoot.querySelector("#today-label").textContent = new Intl.DateTimeFormat(
    "en",
    { dateStyle: "full" },
  )
    .format(new Date())
    .toUpperCase();
  await loadProfile();
  await showView("dashboard");
}

function setMessage(element, message, success = false) {
  if (!element) return;
  element.textContent = message;
  element.classList.toggle("success", success);
}

async function request(path, options = {}) {
  const headers = new Headers(options.headers || {});
  headers.set("Accept", "application/json");
  if (options.body) headers.set("Content-Type", "application/json");
  const token = localStorage.getItem("fitness_token");
  if (token) headers.set("Authorization", `Bearer ${token}`);
  const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (!response.ok) {
    const error = new Error(
      (await response.text()).trim() || `Request failed (${response.status})`,
    );
    error.status = response.status;
    throw error;
  }
  return response;
}

async function requestJson(path, body = {}) {
  const response = await request(path, {
    method: "POST",
    body: JSON.stringify(body),
  });
  return response.json();
}

async function loadRecord(path) {
  try {
    return await requestJson(path);
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

async function showView(view) {
  const requestId = ++viewLoadId;
  const container = appRoot.querySelector("#view-container");
  const template = await loadTemplate(view);
  if (requestId !== viewLoadId) return;
  container.innerHTML = template;
  appRoot.querySelectorAll(".nav-link").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === view);
  });
  appRoot.querySelector("#page-title").textContent =
    {
      dashboard: "Overview",
      workouts: "Workouts",
      stats: "Stats",
      reports: "Reports",
      profile: "Profile",
    }[view] || "Overview";
  appRoot.querySelector("#app-message").textContent = "";
  renderProfile();

  if (view === "dashboard") await loadDashboard();
  if (view === "workouts") await loadWorkouts();
  if (view === "stats") await loadStats();
  if (view === "reports") await loadReports(localDateString());
}

function renderProfile() {
  if (!profileData) return;
  const currentUsername = username() || "Athlete";
  const fullName =
    [profileData.firstname, profileData.lastname].filter(Boolean).join(" ") ||
    currentUsername;
  const age = profileData.age ?? "--";
  const height = profileData.height ?? "--";
  const weight = profileData.weight ?? "--";
  const bmi = profileData.bmi ?? "--";
  const values = {
    "#metric-age": age,
    "#metric-weight": weight,
    "#metric-bmi": bmi,
    "#profile-avatar": currentUsername.slice(0, 1).toUpperCase(),
    "#profile-name": fullName,
    "#profile-demographic": `${age} years · ${profileData.gender || "Member"}`,
    "#profile-username": currentUsername,
    "#profile-firstname": profileData.firstname || "--",
    "#profile-lastname": profileData.lastname || "--",
    "#profile-gender": profileData.gender || "--",
    "#profile-age": `${age} years`,
    "#profile-height": `${height} cm`,
    "#profile-weight": `${weight} kg`,
    "#profile-bmi": bmi,
  };
  for (const [selector, value] of Object.entries(values)) {
    const element = appRoot.querySelector(selector);
    if (element) element.textContent = value;
  }
}

async function loadProfile() {
  const currentUsername = username();
  if (!currentUsername) return;
  try {
    profileData = await requestJson(
      `/getuser/${encodeURIComponent(currentUsername)}`,
      { username: currentUsername },
    );
    renderProfile();
  } catch (error) {
    appRoot.querySelector("#app-message").textContent =
      `Could not load your profile: ${error.message}`;
  }
}

function targetsForProfile() {
  const bmi = Number(profileData?.bmi ?? 0);
  if (bmi < 18) return { water: 3, steps: 10000 };
  if (bmi <= 25) return { water: 3.5, steps: 12000 };
  return { water: 4, steps: 8000 };
}

function planPath(name) {
  return `/getuser/${encodeURIComponent(username())}/${name}`;
}

async function loadPlans() {
  if (planCache) return planCache;
  const safeLoad = async (name) => {
    try {
      return { data: await requestJson(planPath(name)), error: "" };
    } catch (error) {
      return { data: null, error: error.message };
    }
  };
  const [cardio, strength, diet] = await Promise.all([
    safeLoad("cardioplan"),
    safeLoad("workoutplan"),
    safeLoad("dietplan"),
  ]);
  planCache = { cardio, strength, diet };
  return planCache;
}

async function loadToday(date = "") {
  const suffix = date ? `/${encodeURIComponent(date)}` : "";
  const currentUsername = encodeURIComponent(username());
  const [daily, targets] = await Promise.all([
    loadRecord(`/userdailydata/${currentUsername}${suffix}`),
    loadRecord(`/userdailydatatarget/${currentUsername}${suffix}`),
  ]);
  return { daily, targets };
}

function numberValue(value) {
  const parsed = Number.parseFloat(String(value ?? "").replace(/[^\d.-]/g, ""));
  return Number.isFinite(parsed) ? parsed : 0;
}

function targetValue(value) {
  const match = String(value ?? "").match(/[\d.]+/);
  return match ? Number(match[0]) : 0;
}

function workoutLabel(key) {
  const normalized = String(key).toLowerCase();
  return (
    workoutLabels[normalized] || normalized.replace(/([a-z])([A-Z])/g, "$1 $2")
  );
}

function setProgress(selector, value, target) {
  const bar = appRoot.querySelector(selector);
  if (!bar) return;
  const percentage = target > 0 ? Math.min(100, (value / target) * 100) : 0;
  bar.style.width = `${percentage}%`;
}

function renderWorkoutProgress(container, records, emptyMessage) {
  container.replaceChildren();
  if (!records.length) {
    const empty = document.createElement("p");
    empty.className = "empty-state";
    empty.textContent = emptyMessage;
    container.append(empty);
    return;
  }
  for (const record of records) {
    const target = targetValue(record.Target);
    const done = numberValue(record.Done);
    const item = document.createElement("div");
    item.className = "progress-item";
    const name = document.createElement("strong");
    name.textContent = workoutLabel(record.Name);
    const value = document.createElement("span");
    value.className = "progress-value";
    value.textContent = `${done} / ${record.Target || target}`;
    const track = document.createElement("div");
    track.className = "progress-track";
    const fill = document.createElement("span");
    fill.style.width = `${target ? Math.min(100, (done / target) * 100) : 0}%`;
    track.append(fill);
    item.append(name, value, track);
    container.append(item);
  }
}

async function loadDashboard() {
  try {
    const [{ daily, targets }] = await Promise.all([loadToday()]);
    const goals = targetsForProfile();
    const water = numberValue(daily?.water);
    const steps = numberValue(daily?.steps);
    appRoot.querySelector("#dashboard-water").textContent =
      `${water.toFixed(water % 1 ? 1 : 0)} L`;
    appRoot.querySelector("#dashboard-water-goal").textContent =
      `Goal: ${goals.water} L`;
    appRoot.querySelector("#dashboard-water-note").textContent =
      `${Math.max(0, goals.water - water).toFixed(1)} L remaining`;
    appRoot.querySelector("#dashboard-steps").textContent =
      steps.toLocaleString();
    appRoot.querySelector("#dashboard-steps-goal").textContent =
      `Goal: ${goals.steps.toLocaleString()}`;
    appRoot.querySelector("#dashboard-steps-note").textContent =
      `${Math.max(0, goals.steps - steps).toLocaleString()} steps remaining`;
    setProgress("#dashboard-water-progress", water, goals.water);
    setProgress("#dashboard-steps-progress", steps, goals.steps);
    renderWorkoutProgress(
      appRoot.querySelector("#dashboard-workout-list"),
      targets?.Workout || [],
      "No workout targets are available for today.",
    );
  } catch (error) {
    appRoot.querySelector("#app-message").textContent =
      `Could not load today's progress: ${error.message}`;
  }
}

function addPlanItems(container, data, emptyMessage, formatter) {
  container.replaceChildren();
  const entries = data && typeof data === "object" ? Object.entries(data) : [];
  const items = entries.filter(([, value]) => value !== "" && value != null);
  if (!items.length) {
    const empty = document.createElement("p");
    empty.className = "empty-state";
    empty.textContent = emptyMessage;
    container.append(empty);
    return;
  }
  for (const [key, value] of items) {
    const item = document.createElement("div");
    item.className = "plan-item";
    const name = document.createElement("strong");
    name.textContent = formatter(key);
    const target = document.createElement("small");
    target.textContent = String(value);
    item.append(name, target);
    container.append(item);
  }
}

async function loadWorkouts() {
  const goals = targetsForProfile();
  appRoot.querySelector("#plan-water-goal").textContent = goals.water;
  appRoot.querySelector("#plan-steps-goal").textContent =
    goals.steps.toLocaleString();
  const plans = await loadPlans();
  addPlanItems(
    appRoot.querySelector("#cardio-plan"),
    plans.cardio.data,
    plans.cardio.error || "No cardio plan is available for your profile.",
    workoutLabel,
  );
  addPlanItems(
    appRoot.querySelector("#strength-plan"),
    plans.strength.data,
    plans.strength.error || "No strength plan is available for your profile.",
    workoutLabel,
  );
  addPlanItems(
    appRoot.querySelector("#diet-plan"),
    plans.diet.data,
    plans.diet.error || "No diet plan is available for your profile.",
    (meal) => meal[0].toUpperCase() + meal.slice(1),
  );
}

function addExerciseInputs(container, plan, current, emptyMessage) {
  container.replaceChildren();
  const entries = plan && typeof plan === "object" ? Object.entries(plan) : [];
  const items = entries.filter(([, target]) => target !== "" && target != null);
  if (!items.length) {
    const empty = document.createElement("p");
    empty.className = "empty-state";
    empty.textContent = emptyMessage;
    container.append(empty);
    return;
  }
  for (const [key, target] of items) {
    const field = document.createElement("div");
    field.className = "exercise-field";
    const label = document.createElement("label");
    label.htmlFor = `exercise-${key}`;
    label.textContent = workoutLabel(key);
    const targetText = document.createElement("small");
    targetText.textContent = `Target: ${target}`;
    label.append(targetText);
    const input = document.createElement("input");
    input.id = `exercise-${key}`;
    input.name = key;
    input.type = "number";
    input.min = "0";
    input.step = "1";
    input.inputMode = "numeric";
    input.value = current?.[`${key}done`] ?? "";
    input.setAttribute("aria-label", `${workoutLabel(key)} completed today`);
    field.append(label, input);
    container.append(field);
  }
}

async function loadStats() {
  appRoot.querySelector("#stats-date-label").textContent =
    new Intl.DateTimeFormat("en", { dateStyle: "medium" }).format(new Date());
  try {
    const [plans, { daily }] = await Promise.all([loadPlans(), loadToday()]);
    const dailyForm = appRoot.querySelector("#daily-input-form");
    dailyForm.elements.water.value = daily?.water ?? "";
    dailyForm.elements.steps.value = daily?.steps ?? "";
    addExerciseInputs(
      appRoot.querySelector("#cardio-fields"),
      plans.cardio.data,
      daily,
      plans.cardio.error || "No cardio targets are available.",
    );
    addExerciseInputs(
      appRoot.querySelector("#strength-fields"),
      plans.strength.data,
      daily,
      plans.strength.error || "No strength targets are available.",
    );
  } catch (error) {
    appRoot.querySelector("#daily-input-message").textContent =
      `Could not load today's stats: ${error.message}`;
  }
}

async function loadReports(date) {
  const dateInput = appRoot.querySelector("#report-date");
  dateInput.value = date;
  dateInput.max = localDateString();
  const message = appRoot.querySelector("#report-message");
  message.textContent = "";
  try {
    const { daily, targets } = await loadToday(date);
    const goals = targetsForProfile();
    const water = numberValue(daily?.water);
    const steps = numberValue(daily?.steps);
    appRoot.querySelector("#report-water-value").textContent = `${water} L`;
    appRoot.querySelector("#report-water-target").textContent =
      `of ${goals.water} L daily goal`;
    appRoot.querySelector("#report-steps-value").textContent =
      steps.toLocaleString();
    appRoot.querySelector("#report-steps-target").textContent =
      `of ${goals.steps.toLocaleString()} daily goal`;
    const waterBar = appRoot.querySelector("#report-water-bar");
    const stepsBar = appRoot.querySelector("#report-steps-bar");
    waterBar.style.width = `${Math.min(100, (water / goals.water) * 100)}%`;
    stepsBar.style.width = `${Math.min(100, (steps / goals.steps) * 100)}%`;
    const workouts = targets?.Workout || [];
    appRoot.querySelector("#report-workout-count").textContent =
      `${workouts.length} exercises`;
    renderWorkoutProgress(
      appRoot.querySelector("#report-workout-list"),
      workouts,
      daily
        ? "No workout progress was recorded for this date."
        : "No activity was logged on this date.",
    );
  } catch (error) {
    message.textContent = `Could not load this report: ${error.message}`;
  }
}

function updateBmi() {
  const form = appRoot.querySelector("#signup-form");
  if (!form) return;
  const height = Number(form.elements.height.value) / 100;
  const weight = Number(form.elements.weight.value);
  form.elements.bmi.value =
    height > 0 && weight > 0 ? (weight / (height * height)).toFixed(2) : "";
}

async function submitLogin(form) {
  const values = new FormData(form);
  const currentUsername = values.get("username").trim();
  try {
    const response = await request("/login", {
      method: "POST",
      body: JSON.stringify({
        username: currentUsername,
        password: values.get("password"),
      }),
    });
    const result = await response.json();
    localStorage.setItem("fitness_token", result.token);
    localStorage.setItem("fitness_username", currentUsername);
    profileData = null;
    planCache = null;
    await showApp();
  } catch (error) {
    setMessage(
      appRoot.querySelector("#login-message"),
      error.message || "Sign in failed. Check your details.",
    );
  }
}

async function submitSignup(form) {
  const values = new FormData(form);
  const message = appRoot.querySelector("#signup-message");
  if (values.get("password") !== values.get("confirmPassword")) {
    setMessage(message, "Passwords do not match.");
    return;
  }
  const user = {
    firstname: values.get("firstname").trim(),
    lastname: values.get("lastname").trim(),
    username: values.get("username").trim(),
    age: Number(values.get("age")),
    gender: values.get("gender").trim(),
    height: Number(values.get("height")),
    weight: Number(values.get("weight")),
    bmi: Math.round(Number(values.get("bmi"))),
    password: values.get("password"),
  };
  try {
    await request("/signup", { method: "POST", body: JSON.stringify(user) });
    await showAuth("login", {
      username: user.username,
      message: "Account created. Sign in to continue.",
    });
  } catch (error) {
    setMessage(
      message,
      error.message || "Account creation failed. Please try again.",
    );
  }
}

async function saveDailyMetrics(form) {
  const values = new FormData(form);
  const payload = {
    water: Number(values.get("water")),
    steps: Number(values.get("steps")),
  };
  try {
    await request(`/userinput/${encodeURIComponent(username())}`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
    setMessage(
      appRoot.querySelector("#daily-input-message"),
      "Daily metrics saved.",
      true,
    );
    await loadStats();
  } catch (error) {
    setMessage(appRoot.querySelector("#daily-input-message"), error.message);
  }
}

async function saveExerciseProgress(form, messageSelector) {
  const payload = {};
  for (const input of form.querySelectorAll("input[name]")) {
    if (input.value !== "") payload[`${input.name}done`] = Number(input.value);
  }
  if (!Object.keys(payload).length) {
    setMessage(
      appRoot.querySelector(messageSelector),
      "Enter at least one completed value.",
    );
    return;
  }
  try {
    await request(`/userinput/${encodeURIComponent(username())}`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
    setMessage(
      appRoot.querySelector(messageSelector),
      "Workout progress saved.",
      true,
    );
    await loadStats();
  } catch (error) {
    setMessage(appRoot.querySelector(messageSelector), error.message);
  }
}

async function showChat() {
  const container = appRoot.querySelector("#chat-container");
  if (!container.querySelector("#chat-dialog")) {
    container.innerHTML = await loadTemplate("chat");
  }
  container.querySelector("#chat-dialog").showModal();
}

appRoot.addEventListener("click", async (event) => {
  const authButton = event.target.closest("[data-auth]");
  if (authButton) {
    await showAuth(authButton.dataset.auth);
    return;
  }

  if (event.target.closest("#chat-open")) {
    await showChat();
    return;
  }

  if (event.target.closest("#chat-close")) {
    appRoot.querySelector("#chat-dialog")?.close();
    return;
  }

  const viewButton = event.target.closest("[data-view]");
  if (viewButton) {
    await showView(viewButton.dataset.view);
    return;
  }

  const filterButton = event.target.closest("[data-filter]");
  if (filterButton) {
    appRoot.querySelectorAll("[data-filter]").forEach((filter) => {
      filter.classList.toggle("active", filter === filterButton);
    });
    appRoot.querySelectorAll(".workout-card").forEach((card) => {
      card.hidden =
        filterButton.dataset.filter !== "all" &&
        card.dataset.category !== filterButton.dataset.filter;
    });
    return;
  }

  if (event.target.closest("#logout-button")) {
    localStorage.removeItem("fitness_token");
    localStorage.removeItem("fitness_username");
    profileData = null;
    planCache = null;
    await showAuth("login");
  }
});

appRoot.addEventListener("input", (event) => {
  if (
    event.target.matches(
      '#signup-form [name="height"], #signup-form [name="weight"]',
    )
  ) {
    updateBmi();
  }
});

appRoot.addEventListener("change", async (event) => {
  if (event.target.id === "report-date" && event.target.value) {
    await loadReports(event.target.value);
  }
});

appRoot.addEventListener("submit", async (event) => {
  const form = event.target;
  if (
    ![
      "login-form",
      "signup-form",
      "daily-input-form",
      "cardio-form",
      "strength-form",
    ].includes(form.id)
  ) {
    return;
  }
  event.preventDefault();
  if (form.id === "login-form") await submitLogin(form);
  if (form.id === "signup-form") await submitSignup(form);
  if (form.id === "daily-input-form") await saveDailyMetrics(form);
  if (form.id === "cardio-form") {
    await saveExerciseProgress(form, "#cardio-message");
  }
  if (form.id === "strength-form") {
    await saveExerciseProgress(form, "#strength-message");
  }
});

async function initialize() {
  const token = localStorage.getItem("fitness_token");
  if (!token) {
    await showAuth("login");
    return;
  }
  try {
    await request("/check-auth");
    await showApp();
  } catch {
    localStorage.removeItem("fitness_token");
    localStorage.removeItem("fitness_username");
    await showAuth("login");
  }
}

initialize();
