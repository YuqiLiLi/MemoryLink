// Screen Navigation
function enterApp() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('mainApp').classList.add('active');
}

function backToHome() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('homeScreen').classList.add('active');
}

// Tab Navigation
function switchTab(tabName) {
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabBtns.forEach(btn => btn.classList.remove('active'));
    tabContents.forEach(content => content.classList.remove('active'));
    
    if (tabName === 'ar') {
        tabBtns[0].classList.add('active');
        document.getElementById('arViewTab').classList.add('active');
    } else if (tabName === 'list') {
        tabBtns[1].classList.add('active');
        document.getElementById('listViewTab').classList.add('active');
    }
}

// Storytelling Mode Functions
function startRecording() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('recordingScreen').classList.add('active');
    
    // Simulate recording timer
    let seconds = 0;
    const timerInterval = setInterval(() => {
        seconds++;
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        document.getElementById('timer').textContent = 
            `${mins}:${secs.toString().padStart(2, '0')}`;
    }, 1000);
    
    // Store interval ID for cleanup
    window.currentTimer = timerInterval;
}

function stopRecording() {
    if (window.currentTimer) {
        clearInterval(window.currentTimer);
    }
    
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('memoryCreated').classList.add('active');
}

// Exploration Mode Functions
function showMemoryMap() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('memoryMap').classList.add('active');
}

function backToScan() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('mainApp').classList.add('active');
}

function openMemoryNode() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('memoryDetail').classList.add('active');
}

function backToDetail() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('memoryDetail').classList.add('active');
}

function showResponseInput() {
    const screens = document.querySelectorAll('.screen');
    screens.forEach(s => s.classList.remove('active'));
    document.getElementById('responseInput').classList.add('active');
}

function setResponseType(type) {
    const options = document.querySelectorAll('.option-btn');
    options.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');
    
    if (type === 'text') {
        document.getElementById('textInput').classList.remove('hidden');
        document.getElementById('voiceInput').classList.add('hidden');
    } else {
        document.getElementById('textInput').classList.add('hidden');
        document.getElementById('voiceInput').classList.remove('hidden');
    }
}

// Audio Player
let isPlaying = false;
function togglePlay() {
    const playBtn = document.querySelector('.play-btn');
    isPlaying = !isPlaying;
    
    if (isPlaying) {
        playBtn.textContent = '⏸️';
        // Simulate audio progress
        let progress = 40;
        const progressInterval = setInterval(() => {
            if (!isPlaying || progress >= 100) {
                clearInterval(progressInterval);
                playBtn.textContent = '▶️';
                isPlaying = false;
                return;
            }
            progress += 2;
            document.querySelector('.progress-bar').style.width = progress + '%';
        }, 100);
        window.audioProgress = progressInterval;
    } else {
        playBtn.textContent = '▶️';
        if (window.audioProgress) {
            clearInterval(window.audioProgress);
        }
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('ReminiscAR Prototype Loaded');
    
    // Set initial screen
    document.getElementById('homeScreen').classList.add('active');
});


