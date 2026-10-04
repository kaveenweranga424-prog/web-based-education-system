document.addEventListener('DOMContentLoaded', () => {
    const header = document.querySelector('.site-header');
    const menu = document.getElementById('landingMenu');
    const linksWrap = document.getElementById('landingLinks');
    const navLinks = [...document.querySelectorAll('.nav-link')];

    const updateHeader = () => header?.classList.toggle('scrolled', window.scrollY > 16);
    updateHeader();
    window.addEventListener('scroll', updateHeader, { passive: true });

    menu?.addEventListener('click', () => {
        const open = linksWrap.classList.toggle('open');
        menu.setAttribute('aria-expanded', String(open));
    });

    navLinks.forEach(link => link.addEventListener('click', () => {
        linksWrap?.classList.remove('open');
        menu?.setAttribute('aria-expanded', 'false');
    }));

    const sections = [...document.querySelectorAll('main section[id]')];
    const setActiveLink = () => {
        let activeId = 'home';
        sections.forEach(section => {
            if (window.scrollY >= section.offsetTop - 180) activeId = section.id;
        });
        navLinks.forEach(link => link.classList.toggle('active', link.getAttribute('href') === `#${activeId}`));
    };
    window.addEventListener('scroll', setActiveLink, { passive: true });
    setActiveLink();

    const revealObserver = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                revealObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.14 });
    document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

    const counters = document.querySelectorAll('.counter');
    const counterObserver = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            const el = entry.target;
            const target = Number(el.dataset.count || 0);
            const suffix = el.dataset.suffix || '';
            const start = performance.now();
            const duration = 950;
            const animate = now => {
                const progress = Math.min((now - start) / duration, 1);
                const eased = 1 - Math.pow(1 - progress, 3);
                el.textContent = `${Math.round(target * eased)}${suffix}`;
                if (progress < 1) requestAnimationFrame(animate);
            };
            requestAnimationFrame(animate);
            counterObserver.unobserve(el);
        });
    }, { threshold: .5 });
    counters.forEach(counter => counterObserver.observe(counter));

    const roleData = {
        student: {
            icon: 'fa-user-graduate',
            eyebrow: 'STUDENT EXPERIENCE',
            title: 'Stay on top of every class.',
            description: 'See schedules, materials, attendance, fees and results in one simple personal space.',
            points: ['Upcoming classes at a glance', 'Materials and exam results in one place', 'Personal attendance and payment status'],
            visual: [['Next class','Mathematics • 4:30 PM'],['Attendance','94%'],['Latest result','87%']]
        },
        parent: {
            icon: 'fa-people-roof',
            eyebrow: 'PARENT EXPERIENCE',
            title: 'Stay connected to your child’s progress.',
            description: 'Keep an eye on attendance, fees, results and important class updates without repeated phone calls.',
            points: ['Linked view of your child’s records', 'Clear attendance and fee visibility', 'Important notices in one place'],
            visual: [['Student','Kasun Perera'],['Attendance','94%'],['Fee status','Paid']]
        },
        tutor: {
            icon: 'fa-chalkboard-user',
            eyebrow: 'TUTOR EXPERIENCE',
            title: 'Teach with less repeated admin work.',
            description: 'Share materials, mark attendance, enter results and keep students informed from one focused workspace.',
            points: ['Quick access to assigned classes', 'Upload materials and record attendance', 'Publish results and class updates'],
            visual: [['Today','3 classes'],['Attendance','2 completed'],['Materials','1 new upload']]
        }
    };

    const roleCard = document.getElementById('roleCard');
    const roleTabs = document.querySelectorAll('.role-tab');
    const renderRole = key => {
        const data = roleData[key];
        if (!data || !roleCard) return;
        roleCard.innerHTML = `
            <div class="role-card-top">
                <span class="role-icon"><i class="fa-solid ${data.icon}"></i></span>
                <div><small>${data.eyebrow}</small><h3>${data.title}</h3></div>
            </div>
            <p>${data.description}</p>
            <div class="role-points">${data.points.map(p => `<span><i class="fa-solid fa-check"></i>${p}</span>`).join('')}</div>
            <div class="role-visual">${data.visual.map(([a,b]) => `<div class="role-screen-line"><span>${a}</span><strong>${b}</strong></div>`).join('')}</div>
        `;
    };
    roleTabs.forEach(tab => tab.addEventListener('click', () => {
        roleTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        renderRole(tab.dataset.role);
    }));

    const storyCards = [...document.querySelectorAll('.story-card')];
    let storyIndex = 0;
    const showStory = index => {
        if (!storyCards.length) return;
        storyIndex = (index + storyCards.length) % storyCards.length;
        storyCards.forEach((card, i) => card.classList.toggle('active', i === storyIndex));
    };
    document.getElementById('storyPrev')?.addEventListener('click', () => showStory(storyIndex - 1));
    document.getElementById('storyNext')?.addEventListener('click', () => showStory(storyIndex + 1));
    const autoStory = setInterval(() => showStory(storyIndex + 1), 5500);
    document.querySelector('.story-slider')?.addEventListener('mouseenter', () => clearInterval(autoStory), { once: true });

    document.querySelectorAll('.faq-question').forEach(button => {
        button.addEventListener('click', () => {
            const item = button.closest('.faq-item');
            const wasOpen = item.classList.contains('open');
            document.querySelectorAll('.faq-item').forEach(el => el.classList.remove('open'));
            if (!wasOpen) item.classList.add('open');
        });
    });
});
