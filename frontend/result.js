const result = {
    render: function(playResult){
        const gameArea = document.getElementById('gameArea');
        gameArea.innerHTML = '';

        const seqShowArea = document.createElement('div');
        seqShowArea.className = 'd-flex flex-wrap align-items-center';
        gameArea.appendChild(seqShowArea);

        for(let i = 0; i < playResult.gameSettings.playSeq.length; i++){
            const div = document.createElement('div');
            div.className = 'm-2 p-3 align-items-center';
            if(playResult.gameSettings.playSeq[i] == playResult.userSeq[i]){
                const p = document.createElement('p');
                p.innerText = playResult.gameSettings.scale.name[playResult.gameSettings.playSeq[i]];
                p.className = 'text-success';
                div.appendChild(p);
            }else{
                const p1 = document.createElement('p'), p2 = document.createElement('p');
                p1.innerText = playResult.gameSettings.scale.name[playResult.gameSettings.playSeq[i]];
                p1.className = 'text-info';
                if(playResult.userSeq[i] == -1){
                    p2.innerText = '-';
                }else{
                    p2.innerText = playResult.gameSettings.scale.name[playResult.userSeq[i]];
                }
                p2.className = 'text-danger';
                div.appendChild(p1);
                div.appendChild(p2);
            }
            seqShowArea.appendChild(div);
        }
    }
};

