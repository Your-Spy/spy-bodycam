import { GameView } from './gameview.js';
const gameview = new GameView();
let isRecording = false;
let recordingTimeout;

$(document).ready(function () {
    $('.overlayCont').hide();
    $('.currWatchCont').hide();
    $('.RecordInfo').hide();
    $('.recCont').hide();
    $('.askMain').hide();
    $('.vidplaycont').hide();
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
                startRecording(data.hook, data.service);
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
                }, data.recTiming * 1000);
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

        // RECORDS SHOWING
        if (data.action === 'show_records') {
            $('.recInnerScroll').empty();
            $('.recDesc').text(`${data.jobTitle} Database`);

            if (Array.isArray(data.recordData) && data.recordData.length > 0) {
                $.each(data.recordData, function (index, record) {
                    var camBox = $(
                        `
                <div class="camBox">
                    <div class="camInfo">
                        <div class="camTitle">${record.playername}<span class="camStreet"> [${record.street}]</span></div>
                        <div class="camDesc">Date: ${record.date}</div>
                    </div>
                    <div class="camIcons">
                        <div class="camShow" data-stored="${record.videolink}"><i class="fa-solid fa-eye"></i></div>
                        ${data.isBoss ? `<div class="camDelete"><i class="fa-solid fa-trash"></i></div>` : ''}
                    </div>
                </div>
                `
                    );
                    $('.recInnerScroll').append(camBox);
                });
                $('.recCont').show();
            } else {
                $('.recInnerScroll').html('<h1 class="noRecAv">No records available</h1>');
                $('.recCont').show();
            }
        }

        // Refresh Records
        if (data.action === 'refreshrec') {
            $('.recInnerScroll').empty();
            if (Array.isArray(data.recordData) && data.recordData.length > 0) {
                $.each(data.recordData, function (index, record) {
                    var camBox = $(
                        `
                <div class="camBox">
                    <div class="camInfo">
                        <div class="camTitle">${record.playername}<span class="camStreet"> [${record.street}]</span></div>
                        <div class="camDesc">Date: ${record.date}</div>
                    </div>
                    <div class="camIcons">
                        <div class="camShow" data-stored="${record.videolink}"><i class="fa-solid fa-eye"></i></div>
                        ${data.isBoss ? `<div class="camDelete"><i class="fa-solid fa-trash"></i></div>` : ''}
                    </div>
                </div>
                `
                    );
                    $('.recInnerScroll').append(camBox);
                });
                $('.recCont').show();
            } else {
                $('.recInnerScroll').html('<h1 class="noRecAv">No records available</h1>');
                $('.recCont').show();
            }
        }
    });

    let deleteUrl = '';

    // SEARCH AND DATE FILTERS :)
    function updateVisibility(searchText) {
        $('.camBox').each(function () {
            var camTitleText = $(this).find('.camTitle').text().toLowerCase();
            var camDescDate = $(this).find('.camDesc').text().trim().replace('Date: ', '');
            if ((searchText === '' || camTitleText.includes(searchText)) &&
                ($(this).css('display') !== 'none' || camDescDate === $('.selectedDate').val())
            ) {
                $(this).show();
            }
            else if ((searchText === '' || camTitleText.includes(searchText)) &&
                ($('.selectedDate').val() === '')
            ) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    }

    $('.searchInput').on('input', function () {
        var searchText = $(this).val().toLowerCase();
        updateVisibility(searchText);
    });

    $('.selectedDate').on('change', function () {
        var selectedDate = $(this).val();
        $('.camBox').each(function () {
            var camDescDate = $(this).find('.camDesc').text().trim().replace('Date: ', '');
            if (selectedDate === '') {
                $(this).show();
            } else if (selectedDate === camDescDate) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
        var searchText = $('.searchInput').val().toLowerCase();
        updateVisibility(searchText);
    });

    $(document).on('click', '.camDelete', function () {
        const camBox = $(this).closest('.camBox');
        deleteUrl = camBox.find('.camShow').data('stored');
        $('.askMain').fadeIn();
    });

    $(document).on('click', '.askBtn:nth-child(1)', function () {
        $('.askMain').fadeOut();
        if (deleteUrl) {
            $.post(`https://${GetParentResourceName()}/deleteVideo`, JSON.stringify({
                vidurl: deleteUrl
            }));
        }
    });

    $(document).on('click', '.askBtn:nth-child(2)', function () {
        $('.askMain').fadeOut();
    });

    $(document).on('click', '.camShow', function () {
        var videoUrl = $(this).data('stored');
        $('.vidPlayer').attr('src', videoUrl);
        $('.vidplaycont').show();
    });

    $(document).on('click', '.vidPlayerIcon', function () {
        $('.vidplaycont').hide();
        $('.vidPlayer').attr('src', '');
    });

    $(document).on('click', function (event) {
        if ($(event.target).is('.vidplaycont')) {
            $('.vidplaycont').hide();
            $('.vidPlayer').attr('src', '');
        }
    });

    $(document).on('keydown', function (e) {
        if (e.which === 27) {
            $('.askMain').hide();
            $('.searchInput').val('');
            $('.selectedDate').val('');
            $('.recCont').hide();
            $('.vidplaycont').hide();
            $('.vidPlayer').attr('src', '');
            $.post(`https://${GetParentResourceName()}/closeRecUI`, '{}');
        }
    });
});

let mediaRecorder;
let audioStream;
const canvasElement = document.querySelector('canvas');

async function uploadBlob(videoBlob, hook, service) {
    $.post(`https://${GetParentResourceName()}/exitBodyCam`, '{}');
    const formData = new FormData();
    try {
        let response, responseData;
        if (service === 'fivemanage') {
            formData.append('video', videoBlob);
            response = await fetch('https://api.fivemanage.com/api/video', {
                method: 'POST',
                headers: {
                    Authorization: hook,
                },
                body: formData,
            });
            if (!response.ok) {
                throw new Error(`Failed to upload video to FiveManage: ${response.status}`);
            }
            responseData = await response.json();
            $.post(`https://${GetParentResourceName()}/videoLog`, JSON.stringify({
                vidurl: responseData.url
            }));
        } else if (service === 'fivemerr') {
            formData.append('file', videoBlob, 'video.webm');
            response = await fetch('https://api.fivemerr.com/v1/media/videos', {
                method: 'POST',
                headers: {
                    Authorization: hook,
                },
                body: formData,
            });
            if (!response.ok) {
                throw new Error(`Failed to upload video to Fivemerr: ${response.status}`);
            }
            responseData = await response.json();
            $.post(`https://${GetParentResourceName()}/videoLog`, JSON.stringify({
                vidurl: responseData.url
            }));
        } else if (service === 'discord') {
            formData.append('file', videoBlob, 'video.webm');
            response = await fetch(hook, {
                method: 'POST',
                body: formData,
            });
            if (!response.ok) {
                throw new Error(`Failed to upload video to Discord: ${response.status}`);
            }
            responseData = await response.json();
            $.post(`https://${GetParentResourceName()}/videoLog`, JSON.stringify({
                vidurl: responseData.attachments[0].url
            }));
        }
    } catch (error) {
        console.error('^1[ERROR]:^3', error.message);
    }
}

async function startMicrophoneCapture() {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        return stream;
    } catch (error) {
        console.error('Microphone capture failed. Recording video only.');
        return null;
    }
}

async function startRecording(hook, service) {
    audioStream = await startMicrophoneCapture();
    if (!isRecording){
        if (audioStream) {
            audioStream.getAudioTracks().forEach(track => track.stop());
        }
        return 
    }
    console.log('Video Recording Started');
    const gameView = gameview.createGameView(canvasElement);
    const canvasStream = canvasElement.captureStream(30);

    // Combine audio and video streams
    const combinedStream = new MediaStream([
        ...canvasStream.getVideoTracks(),
        ...(audioStream ? audioStream.getAudioTracks() : [])
    ]);

    const videoChunks = [];
    window.gameView = gameView;
    mediaRecorder = new MediaRecorder(combinedStream, { mimeType: 'video/webm;codecs=vp9' });
    mediaRecorder.start();
    mediaRecorder.ondataavailable = (e) => e.data.size > 0 && videoChunks.push(e.data);
    mediaRecorder.onstop = async () => {
        const videoBlob = new Blob(videoChunks, { type: 'video/webm' });
        if (videoBlob.size > 0) {
            uploadBlob(videoBlob, hook, service);
        }
        if (audioStream) {
            audioStream.getAudioTracks().forEach(track => track.stop());
        }
    };
}

function stopRecording() {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
    }
}