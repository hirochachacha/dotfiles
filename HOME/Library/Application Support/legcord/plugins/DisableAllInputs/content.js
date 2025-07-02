console.log(">> LEGCORD EXTENSION: disabling all input boxes <<");

setInterval(() => {
  document.querySelectorAll('main div[contenteditable="true"]').forEach(
    (div) => {
      div.removeAttribute("contenteditable");
      div.blur();
    },
  );
}, 1000);

document.addEventListener("keydown", (e) => {
  if (
    e.target.getAttribute("contenteditable") === "true" &&
    e.target.closest("main")
  ) {
    e.preventDefault();
    e.stopPropagation();
  }
}, true);
