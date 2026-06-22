/* ============================================================
   KakoBuy Spreadsheet — Main Interactions
   ============================================================ */
(function () {
  'use strict';

  // --- FAQ Accordion ---
  function initFAQ() {
    var faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(function (item) {
      var question = item.querySelector('.faq-question');
      if (!question) return;
      question.addEventListener('click', function () {
        var isOpen = item.classList.contains('open');
        // Close all others (optional: single-open behavior)
        // faqItems.forEach(function (other) { other.classList.remove('open'); other.querySelector('.faq-question')?.setAttribute('aria-expanded', 'false'); });
        if (isOpen) {
          item.classList.remove('open');
          question.setAttribute('aria-expanded', 'false');
        } else {
          item.classList.add('open');
          question.setAttribute('aria-expanded', 'true');
        }
      });
    });
  }

  // --- Back to Top ---
  function initBackToTop() {
    var btn = document.getElementById('backToTop');
    if (!btn) return;

    var ticking = false;
    window.addEventListener('scroll', function () {
      if (!ticking) {
        requestAnimationFrame(function () {
          if (window.scrollY > 400) {
            btn.classList.add('visible');
          } else {
            btn.classList.remove('visible');
          }
          ticking = false;
        });
        ticking = true;
      }
    });

    btn.addEventListener('click', function () {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  // --- Contact Form (simulated submit) ---
  function initContactForm() {
    var form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var feedback = document.getElementById('formFeedback');
      if (feedback) {
        feedback.textContent = 'Thank you for your message! We typically respond within 1-2 business days.';
        feedback.style.display = 'block';
        feedback.style.color = '#10b981';
        feedback.style.fontWeight = '600';
        feedback.style.marginTop = '16px';
      }
      form.reset();
      setTimeout(function () {
        if (feedback) feedback.style.display = 'none';
      }, 8000);
    });
  }

  // --- Current Year in Footer ---
  function initFooterYear() {
    var yearEl = document.getElementById('currentYear');
    if (yearEl) {
      yearEl.textContent = new Date().getFullYear();
    }
  }

  // --- Active nav link highlighting ---
  function initActiveNav() {
    var currentPath = window.location.pathname;
    var navLinks = document.querySelectorAll('.header-nav a');
    navLinks.forEach(function (link) {
      var href = link.getAttribute('href');
      if (!href) return;
      // Match the end of the path
      if (currentPath.endsWith(href.replace('./', '/')) || 
          (href === './index.html' && (currentPath === '/' || currentPath.endsWith('/index.html')))) {
        link.style.color = 'var(--color-primary)';
        link.style.fontWeight = '700';
      }
    });
  }

  // --- Initialize all ---
  initFAQ();
  initBackToTop();
  initContactForm();
  initFooterYear();
  initActiveNav();
})();
