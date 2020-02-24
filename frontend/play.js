const play = {
    renderUI: function(gameSettings, audioData){
        const gameArea = document.getElementById('gameArea');
        gameArea.innerHTML = '';

        const userPlayButtons = [];
        const userPlayButtonRow = document.createElement('div');
        userPlayButtonRow.className = 'row';
        gameArea.appendChild(userPlayButtonRow);
        for(let i = 0; i < gameSettings.range; i++){
            const userPlayButtonCol = document.createElement('div');
            userPlayButtonCol.className = 'col text-center';
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-primary';
            button.innerText = gameSettings.scale.name[i];
            button.onclick =
                () => {
                    audioData.user[i].currentTime = 0;
                    audioData.user[i].play();
                };
            userPlayButtons.push(button);

            userPlayButtonCol.appendChild(button);
            userPlayButtonRow.appendChild(userPlayButtonCol);
        }
        return userPlayButtons;
    },
    playAndResult: function(gameSettings, audioData){
        const userPlayButtons = this.renderUI(gameSettings, audioData);

        const MS_PER_SEC = 1000;
        const SEC_PER_MIN = 60;
        const interval = MS_PER_SEC / (gameSettings.tempo / SEC_PER_MIN);
        const userSeq = new Array(gameSettings.length).fill(-1);
        
        let idx = 0;
        const timerId = setInterval(
            () => {
                if(idx >= gameSettings.playSeq.length){
                    clearInterval(timerId);
                    result.render(gameSettings, userSeq, audioData);
                }else{
                    audioData.auto[gameSettings.playSeq[idx]].currentTime = 0;
                    audioData.auto[gameSettings.playSeq[idx]].play();
                    idx++;
                }
            },
            interval
        );
    },
    loadAndPlay: function(gameSettings){
        document.getElementById('gameArea').innerHTML = "Loading...";
        const autoAudioData = gameSettings.scale.pitch.
              map(x => gameSettings.rootNote + x).
              map(x => new Audio(`mp3/${x}.mp3`));
        const userAudioData = gameSettings.scale.pitch.
              map(x => gameSettings.rootNote + x).
              map(x => new Audio(`mp3/${x}.mp3`));
        const audioData = {
            auto: autoAudioData,
            user: userAudioData
        };
        
        const timerId = setInterval(
            () => {
                const HAVE_ENOUGH_DATA = 4;
                if(
                    autoAudioData.every(x => x.readyState >= HAVE_ENOUGH_DATA)
                        && userAudioData.every(x => x.readyState >= HAVE_ENOUGH_DATA)
                ){
                    clearInterval(timerId);
                    this.playAndResult(gameSettings, audioData);
                }
            },
            100
        );
    },
    
    start: function(gameSettings){
        this.loadAndPlay(gameSettings);
    },
};
