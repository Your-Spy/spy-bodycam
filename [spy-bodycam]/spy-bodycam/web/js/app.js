$(document).ready(function () {
    $('.overlayCont').hide();
    $('.currWatchCont').hide();
    const beepSound = document.getElementById('beep-sound');
    const offSound = document.getElementById('off-sound');

    function updateTime() {
        const date = new Date();
        // Adjust for the -0500 offset
        date.setUTCHours(date.getUTCHours() - 5);

        // Format date components
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
            interval = setInterval(updateTime, 1000); // Start updating time every second
            $('.bodyNum').text(data.bodyname);
            $('.bodyCallsign').text(data.callsign);
            $('.overlayCont').fadeIn();
            beepSound.play();
            // beepSound.currentTime = 0;
        } else if (data.action === 'close') {
            clearInterval(interval); // Stop updating time when closing the overlay
            $('.overlayCont').fadeOut();
            offSound.play();
        }
        if (data.action === 'openWatch') {
            const WatchText = "BODY " + data.bodyId +" "+ data.name
            $('.watchInText').text(WatchText);
            $('.backInText').text(data.exitKey);
            $('.currWatchCont').fadeIn();
        } else if (data.action === 'closeWatch') {
            $('.currWatchCont').fadeOut();
        }
    });
});
