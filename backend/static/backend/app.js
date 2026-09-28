document.addEventListener("DOMContentLoaded", () => {
    const passwordToggle = document.querySelector("[data-password-toggle]");
    if (passwordToggle) {
        const field = passwordToggle.closest(".password-field")?.querySelector("input");
        passwordToggle.addEventListener("click", () => {
            if (!field) return;
            const show = field.type === "password";
            field.type = show ? "text" : "password";
            passwordToggle.textContent = show ? "Hide" : "Show";
            passwordToggle.setAttribute("aria-label", show ? "Hide password" : "Show password");
        });
    }

    const menuToggle = document.querySelector("[data-menu-toggle]");
    const sidebar = document.getElementById("sidebar");
    if (menuToggle && sidebar) {
        menuToggle.addEventListener("click", () => {
            const open = sidebar.classList.toggle("open");
            menuToggle.setAttribute("aria-expanded", String(open));
        });
    }
});
