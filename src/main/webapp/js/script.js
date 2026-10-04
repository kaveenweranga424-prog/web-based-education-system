document.addEventListener("DOMContentLoaded", () => {
    const navbar = document.getElementById("navbar");
    const menuToggle = document.getElementById("menuToggle");
    const navLinks = document.getElementById("navLinks");
    const navItems = document.querySelectorAll(".nav-link");
    const backToTop = document.getElementById("backToTop");
    const sections = document.querySelectorAll("main section[id]");

    // Mobile navigation
    menuToggle.addEventListener("click", () => {
        const isOpen = navLinks.classList.toggle("open");
        menuToggle.classList.toggle("open", isOpen);
        menuToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
    });

    navItems.forEach((link) => {
        link.addEventListener("click", () => {
            navLinks.classList.remove("open");
            menuToggle.classList.remove("open");
            menuToggle.setAttribute("aria-expanded", "false");
        });
    });

    // Smooth scrolling for internal links
    document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
        anchor.addEventListener("click", (event) => {
            const targetId = anchor.getAttribute("href");
            if (!targetId || targetId === "#") return;

            const target = document.querySelector(targetId);
            if (!target) return;

            event.preventDefault();
            target.scrollIntoView({ behavior: "smooth", block: "start" });
        });
    });

    // Navbar / back to top on scroll
    const onScroll = () => {
        const y = window.scrollY;

        navbar.classList.toggle("scrolled", y > 30);
        backToTop.classList.toggle("show", y > 650);

        // Active nav link
        let currentId = "home";
        sections.forEach((section) => {
            const sectionTop = section.offsetTop - 160;
            if (y >= sectionTop) currentId = section.id;
        });

        navItems.forEach((link) => {
            const href = link.getAttribute("href");
            link.classList.toggle("active", href === `#${currentId}`);
        });
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    backToTop.addEventListener("click", () => {
        window.scrollTo({ top: 0, behavior: "smooth" });
    });

    // Scroll reveal
    const revealObserver = new IntersectionObserver(
        (entries, observer) => {
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;
                entry.target.classList.add("visible");
                observer.unobserve(entry.target);
            });
        },
        { threshold: 0.12, rootMargin: "0px 0px -50px 0px" }
    );

    document.querySelectorAll(".reveal").forEach((el) => revealObserver.observe(el));

    // Dashboard progress animation
    const progressBars = document.querySelectorAll(".progress-bar");

    const progressObserver = new IntersectionObserver(
        (entries, observer) => {
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;
                const bar = entry.target;
                bar.style.width = bar.dataset.width || "0%";
                observer.unobserve(bar);
            });
        },
        { threshold: 0.4 }
    );

    progressBars.forEach((bar) => progressObserver.observe(bar));

    // Analytics bar animation
    const chartBars = document.querySelectorAll(".bar");

    const chartObserver = new IntersectionObserver(
        (entries, observer) => {
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;

                chartBars.forEach((bar, index) => {
                    const height = Number(bar.dataset.height || 0);
                    setTimeout(() => {
                        bar.style.height = `${height}%`;
                    }, index * 80);
                });

                observer.unobserve(entry.target);
            });
        },
        { threshold: 0.35 }
    );

    const chart = document.querySelector(".chart");
    if (chart) chartObserver.observe(chart);

    // Close mobile menu when resizing to desktop
    window.addEventListener("resize", () => {
        if (window.innerWidth > 900) {
            navLinks.classList.remove("open");
            menuToggle.classList.remove("open");
            menuToggle.setAttribute("aria-expanded", "false");
        }
    });
});