function goToLogin() {
    window.location.href = '/login';
}

document.addEventListener('DOMContentLoaded', async () => {
    const log = (msg, emoji = '📄') => console.log(`${emoji} [Landing] ${msg}`);
    log('Session check starting...');

    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000); // 5s timeout

        const response = await fetch('/check-session', { signal: controller.signal });
        clearTimeout(timeout);

        log(`Response status: ${response.status}`, '📡');

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        log(`Session data: ${JSON.stringify(data)}`, '📋');

        if (data.loggedIn) {
            document.body.classList.add('logged-in');
            log('User logged in → visual blur disabled', '🎨');
        } else {
            log('User not logged in → keeping blur', '🚫');
        }

    } catch (err) {
        log(`Session check failed: ${err.message}`, '❌');
        // Safe fallback → assume logged out state
    }

    const imageExists = async (url) => {
        try {
            const response = await fetch(url, { method: 'HEAD' });
            return response.ok;
        } catch (error) {
            return false;
        }
    };

    const updatePlaceholders = async () => {
        const photo1 = document.querySelector('.photo-1 img');
        const photo2 = document.querySelector('.photo-2 img');

        if (await imageExists('/assets/img1.jpg')) {
            photo1.src = '/assets/img1.jpg';
        }

        if (await imageExists('/assets/img2.jpg')) {
            photo2.src = '/assets/img2.jpg';
        }
    };

    updatePlaceholders();
});
