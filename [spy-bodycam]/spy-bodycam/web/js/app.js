import { GameView } from '../../node_modules/fivem-game-view/src/index.js';
const gameview = new GameView();
let isRecording = false;
let recordingTimeout;

$(document).ready(function () {
    $('.overlayCont').hide();
    $('.currWatchCont').hide();
    $('.RecordInfo').hide();
    const beepSound = document.getElementById('beep-sound');
    const offSound = document.getElementById('off-sound');

    function updateTime() {
        const date = new Date();
        date.setUTCHours(date.getUTCHours() - 5);

        const month = ("0" + (date.getMonth() + 1)).slice(-2);
        const day = ("0" + date.getDate()).slice(-2);
        const hours = ("0" + date.getHours()).slice(-2);
        const minutes = ("0" + date.getMinutes()).slice(-2);
        const seconds = ("0" + date.getSeconds()).slice(-2);

        const gameTime = `${month}-${day} ${hours}:${minutes}:${seconds}-0500`;

        $('.bodyDate').html('<i class="fa-solid fa-circle fa-fade bodyIcon"></i>' + gameTime);
    }

    let interval;

    window.addEventListener('message', function (event) {
        const data = event.data;
        if (data.action === 'open') {
            updateTime();
            interval = setInterval(updateTime, 1000);
            $('.bodyNum').text(data.bodyname);
            $('.bodyCallsign').text(data.callsign);
            $('.overlayCont').removeClass('popOut').addClass('popIn').show();
            beepSound.play();
        } else if (data.action === 'close') {
            clearInterval(interval);
            $('.overlayCont').removeClass('popIn').addClass('popOut').one('animationend', function () {
                $(this).hide();
                $(this).removeClass('popOut');
            });
            offSound.play();
        }
        if (data.action === 'openWatch') {
            let typeCam;
            let plateText;
            let carText;

            if (data.debug) {
                var controlsHtml = `
                    <span class="watchInText typeCam">Controls</span>
                    <br>
                    <span class="watchInText typeCam">W -> Up</span>
                    <br>
                    <span class="watchInText typeCam">S -> Down</span>
                    <br>
                    <span class="watchInText typeCam">A -> Left</span>
                    <br>
                    <span class="watchInText typeCam">D -> Right</span>
                    <br>
                    <span class="watchInText typeCam">Q -> Forward</span>
                    <br>
                    <span class="watchInText typeCam">E -> Backward</span>
                `;
                document.querySelector('.userLaber').innerHTML = controlsHtml;
            } else {
                if (data.isbodycam) {
                    typeCam = "BODYCAM";
                    plateText = "CamID: " + data.bodyId;
                    carText = "Name: " + data.name;
                } else {
                    typeCam = "DASHCAM";
                    plateText = "Plate: " + data.bodyId;
                    carText = "Car: " + data.name;
                }
                document.querySelector('.typeCam').textContent = typeCam;
                document.querySelector('.plateText').textContent = plateText;
                document.querySelector('.carText').textContent = carText;
            }
            $('.backInText').text(data.exitKey);
            $('.currWatchCont').fadeIn();
        } else if (data.action === 'closeWatch') {
            $('.currWatchCont').fadeOut();
        }
        if (data.action === 'toggle_record') {
            clearTimeout(recordingTimeout); 
            if (!isRecording) {
                // Start recording
                isRecording = true;
                $('.HeadText').html('<i class="fa-solid fa-circle fa-fade bodyIcon" style="color: rgb(173, 8, 8);"></i>' + 'Recording Started');
                $('.RecordInfo').fadeIn();
                startRecording(data.hook);
                recordingTimeout = setTimeout(() => {
                    if (isRecording) {
                        // Stop recording automatically after 30 seconds
                        isRecording = false;
                        $('.HeadText').html('<i class="fa-solid fa-circle bodyIcon" style="color: white;"></i>' + 'Recording Stopped');
                        setTimeout(() => {
                            $('.RecordInfo').fadeOut();
                        }, 2000);
                        stopRecording();
                    }
                }, 30000);
            } else {
                // Stop recording
                isRecording = false;
                $('.HeadText').html('<i class="fa-solid fa-circle bodyIcon" style="color: white;"></i>' + 'Recording Stopped');
                clearTimeout(recordingTimeout); 
                setTimeout(() => {
                    $('.RecordInfo').fadeOut();
                }, 2000);
                stopRecording();
            }
        }
        if (data.action === 'cancel_rec_force') {
          if (isRecording) {
              // Force stop recording
              isRecording = false;
              $('.HeadText').html('<i class="fa-solid fa-circle bodyIcon" style="color: white;"></i>' + 'Recording Stopped');
              clearTimeout(recordingTimeout); 
              setTimeout(() => {
                  $('.RecordInfo').fadeOut();
              }, 1000);
              stopRecording();
          }
      }
    });
});

let mediaRecorder;
const canvasElement = document.querySelector('canvas');
async function uploadBlob(videoBlob,hook) {
    $.post(`https://${GetParentResourceName()}/exitBodyCam`, '{}');
    const formData = new FormData();
    formData.append('file', videoBlob, 'video.webm');
    try {
        const response = await fetch(hook, {
            method: 'POST',
            body: formData,
        });
        if (!response.ok) {
            throw new Error(`Failed to upload video: ${response.status} ${response.statusText}`);
        }
        const responseData = await response.json();
        $.post(`https://${GetParentResourceName()}/videoLog`, JSON.stringify({
            vidurl: responseData.attachments[0].url
        }));
    } catch (error) {
        console.error('Failed to upload video:', error.message);
    }
}

function startRecording(hook) {
    const gameView = gameview.createGameView(canvasElement);
    const videoStream = canvasElement.captureStream(30);
    const videoChunks = [];
    window.gameView = gameView;
    mediaRecorder = new MediaRecorder(videoStream, { mimeType: 'video/webm;codecs=vp9' });
    mediaRecorder.start();
    mediaRecorder.ondataavailable = (e) => e.data.size > 0 && videoChunks.push(e.data);
    mediaRecorder.onstop = async () => {
        const videoBlob = new Blob(videoChunks, { type: 'video/webm' });
        if (videoBlob.size > 0) {
            uploadBlob(videoBlob,hook);
        }
    };
}

function stopRecording() {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
    }
}
