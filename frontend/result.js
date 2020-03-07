const result = {
    storeToLocalStorage: function(playData){
        const storage = window.localStorage;
        const storageData = JSON.parse(storage.getItem('earTrainer'));

        const newData = {
            defaultSettings: storageData.defaultSettings,
            playHistory: [playData]
        };
        if(storageData.playHistory != null){
            newData.playHistory = storageData.playHistory.concat(newData.playHistory);
        }
        storage.setItem('earTrainer', JSON.stringify(newData));
    },
    
    render: function(playData){
        this.storeToLocalStorage(playData);
        
        const gameSettings = playData.gameSettings;
        const playResult = playData.playResult;
        const gameArea = document.getElementById('gameArea');
        gameArea.innerHTML = `
<div>
<button id="toMenuButton" type="button" class="btn btn-primary">Menu</button>
<button id="restartButton" type="button" class="btn btn-primary">Restart</button>
</div>
`;
        document.getElementById('toMenuButton').onclick = function(){
            menu.render();
        };
        document.getElementById('restartButton').onclick = function(){
            play.start(gameSettings);
        };

        const seqShowArea = document.createElement('div');
        seqShowArea.className = 'd-flex flex-wrap align-items-center';
        gameArea.appendChild(seqShowArea);

        for(let i = 0; i < gameSettings.playSeq.length; i++){
            const div = document.createElement('div');
            div.className = 'm-2 p-3 align-items-center';
            if(gameSettings.playSeq[i] == playResult.userSeq[i]){
                const p = document.createElement('p');
                p.innerText = gameSettings.scale.name[gameSettings.playSeq[i]];
                p.className = 'text-success';
                div.appendChild(p);
            }else{
                const p1 = document.createElement('p'), p2 = document.createElement('p');
                p1.innerText = gameSettings.scale.name[gameSettings.playSeq[i]];
                p1.className = 'text-info';
                if(playResult.userSeq[i] == -1){
                    p2.innerText = '-';
                }else{
                    p2.innerText = gameSettings.scale.name[playResult.userSeq[i]];
                }
                p2.className = 'text-danger';
                div.appendChild(p1);
                div.appendChild(p2);
            }
            seqShowArea.appendChild(div);
        }
    }
};

