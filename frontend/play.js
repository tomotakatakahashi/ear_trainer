const play = {
    playIdx: 0,
    audioData: {},
    gameSettings: {},
    userSeq: [],
    userPlayButtons: [],
    buttonOnClick: function(idx){
        //this.audioData.user[idx].currentTime = 0;
        //this.audioData.user[idx].play();

        this.userSeq[this.playIdx - 1] = idx;
        for(let i = 0; i < this.userPlayButtons.length; i++){
            this.userPlayButtons[i].className = 'btn btn-secondary btn-block';
            //this.userPlayButtons[i].disabled = true;
        }

        if(this.gameSettings.playSeq[this.playIdx - 1] == idx){
            this.userPlayButtons[idx].className = 'btn btn-success btn-block';
        }else{
            this.userPlayButtons[idx].className = 'btn btn-danger btn-block';
            this.userPlayButtons[this.gameSettings.playSeq[this.playIdx - 1]].className = 'btn btn-info btn-block';
        }
    },

    renderUI: function(gameSettings, audioData){
        const gameArea = document.getElementById('gameArea');
        gameArea.innerHTML = '';

        document.addEventListener(
            'keydown',
            (event) => {
                const keys = ['a', 's', 'd', 'f', 'j', 'k', 'l'];
                const keyName = event.key;
                for(let i = 0; i < this.gameSettings.range; i++){
                    if(keyName == keys[i]){
                        this.buttonOnClick(i);
                    }
                }
            }
        );

        const userPlayButtons = [];
        const userPlayButtonRow = document.createElement('div');
        userPlayButtonRow.className = 'row';
        gameArea.appendChild(userPlayButtonRow);
        for(let i = 0; i < this.gameSettings.range; i++){
            const userPlayButtonCol = document.createElement('div');
            userPlayButtonCol.className = 'col text-center';
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-primary btn-block';
            button.innerText = this.gameSettings.scale.name[i];
            button.onclick =
                () => this.buttonOnClick(i);

            userPlayButtons.push(button);

            userPlayButtonCol.appendChild(button);
            userPlayButtonRow.appendChild(userPlayButtonCol);
        }
        this.userPlayButtons = userPlayButtons;
    },
    playAndResult: function(){
        this.renderUI();

        const MS_PER_SEC = 1000;
        const SEC_PER_MIN = 60;
        const interval = MS_PER_SEC / (this.gameSettings.tempo / SEC_PER_MIN);
        this.userSeq = new Array(this.gameSettings.length).fill(-1);
        
        this.playIdx = 0;
        const timerId = setInterval(
            () => {
                if(this.playIdx >= this.gameSettings.playSeq.length){
                    clearInterval(timerId);
                    result.render(this);
                }else{
                    this.audioData.auto[this.gameSettings.playSeq[this.playIdx]].seek(0);
                    this.audioData.auto[this.gameSettings.playSeq[this.playIdx]].play();
                    this.playIdx++;
                    for(let i = 0; i < this.userPlayButtons.length; i++){
                        this.userPlayButtons[i].disabled = false;
                        this.userPlayButtons[i].className = 'btn btn-primary btn-block';
                    }
                }
            },
            interval
        );
    },
    loadAndPlay: function(){
        document.getElementById('gameArea').innerHTML = "Loading...";
        const autoAudioData = this.gameSettings.scale.pitch.
              map(x => this.gameSettings.rootNote + x).
              map(x => new Howl({src: `mp3/${x}.mp3`}));
        const userAudioData = this.gameSettings.scale.pitch.
              map(x => this.gameSettings.rootNote + x).
              map(x => new Audio(`mp3/${x}.mp3`));
        this.audioData = {
            auto: autoAudioData,
            user: userAudioData
        };
        
        const timerId = setInterval(
            () => {
                const HAVE_ENOUGH_DATA = 4;
                if(true || 
                    autoAudioData.every(x => x.readyState >= HAVE_ENOUGH_DATA)
                        && userAudioData.every(x => x.readyState >= HAVE_ENOUGH_DATA)
                ){
                    clearInterval(timerId);
                    this.playAndResult();
                }
            },
            100
        );
    },
    
    start: function(gameSettings){
        this.gameSettings = gameSettings;
        this.loadAndPlay();
    },
};
