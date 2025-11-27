document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("year").textContent = new Date().getFullYear();
  
    document.getElementById("demo-btn").addEventListener("click", () => {
      alert("Static site is working!");
    });
  });
  