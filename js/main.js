/* =========================================================
   ETERRNO RESORT – SITE BEHAVIOUR
   1. Header changes colour when you scroll
   2. Mobile hamburger menu
   3. Gallery lightbox (click a photo to enlarge)
   4. Enquiry form checks
   5. Footer year
   ========================================================= */

// ---------- 1. Header background on scroll ----------
const header = document.querySelector(".site-header");

function updateHeader() {
  header.classList.toggle("scrolled", window.scrollY > 40);
}

window.addEventListener("scroll", updateHeader);
updateHeader();

// ---------- 2. Mobile menu ----------
const navToggle = document.querySelector(".nav-toggle");

function setMenu(open) {
  header.classList.toggle("nav-open", open);
  navToggle.setAttribute("aria-expanded", open);
  navToggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  document.body.style.overflow = open ? "hidden" : "";
}

navToggle.addEventListener("click", () => {
  setMenu(!header.classList.contains("nav-open"));
});

// Close the menu after tapping a link
document.querySelectorAll(".site-nav a").forEach((link) => {
  link.addEventListener("click", () => setMenu(false));
});

// ---------- 3. Gallery lightbox ----------
const lightbox = document.getElementById("lightbox");
const lightboxImg = lightbox.querySelector("img");

document.querySelectorAll(".gallery-item img").forEach((img) => {
  img.parentElement.addEventListener("click", () => {
    // Load a larger version of the same photo
    lightboxImg.src = img.src.replace(/w=\d+/, "w=1800");
    lightboxImg.alt = img.alt;
    lightbox.classList.add("open");
    lightbox.setAttribute("aria-hidden", "false");
  });
});

function closeLightbox() {
  lightbox.classList.remove("open");
  lightbox.setAttribute("aria-hidden", "true");
}

lightbox.addEventListener("click", (event) => {
  // Close when clicking the dark background or the × button, not the photo
  if (event.target !== lightboxImg) closeLightbox();
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    closeLightbox();
    setMenu(false);
  }
});

// ---------- 4. Enquiry form ----------
const form = document.getElementById("enquiry-form");
const status = document.getElementById("form-status");
const checkin = form.elements.checkin;
const checkout = form.elements.checkout;

// Stop people picking dates in the past
const today = new Date().toISOString().split("T")[0];
checkin.min = today;
checkout.min = today;

checkin.addEventListener("change", () => {
  checkout.min = checkin.value || today;
});

form.addEventListener("submit", (event) => {
  event.preventDefault();

  // Highlight any required field that is empty or invalid
  let valid = true;
  form.querySelectorAll("[required]").forEach((field) => {
    const ok = field.checkValidity();
    field.classList.toggle("invalid", !ok);
    if (!ok) valid = false;
  });

  if (valid && checkout.value <= checkin.value) {
    checkout.classList.add("invalid");
    status.textContent = "Check-out must be after check-in.";
    status.className = "form-status error";
    return;
  }

  if (!valid) {
    status.textContent = "Please fill in the highlighted fields.";
    status.className = "form-status error";
    return;
  }

  // NOTE: this form does not send emails yet. To receive enquiries,
  // connect it to a form service (for example Formspree or Netlify Forms).
  const name = form.elements.name.value.split(" ")[0];
  status.textContent = `Thank you, ${name}! We'll be in touch within 24 hours.`;
  status.className = "form-status success";
  form.reset();
});

// ---------- 5. Footer year ----------
document.getElementById("year").textContent = new Date().getFullYear();
