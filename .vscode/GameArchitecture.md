# Game Logic 

3 Army types 
  - Tank 
  - Infantry 
  - Artillery 

Tank > Infantry 
Artillery > Tank 
Infantry > Artillery 

We have players with cities, and each player is trying to defend their cities, or attack other cities. 
Players choose a defense for their city which could be a tank, artillery or infantry. Then another player chooses which city to attack (by city Id). They choose what to attack with, but they do not know what the city is defending with. 

Once, the attack is revealed on-chain(public), the defender has 24 hours to reveal his army, and call finalize() function. 

If, he does not - then attacker can call forfeit() and win.

- Tank vs Infantry (Tank wins 75% of the time)
- Artillery vs Tank (Artllery wins 75% of the time)
- Infantry vs Artillery (Infantry wins 75% of the time)


## States

 mapping(playerId => cityId)
 mapping(cityId => armyHash)
 enum ArmyType {tank, artillery, infantry}
 Battle {
    attacker - 
    defencer - 
    defenderArmyHash - 
    attackedAt - 
 }  


## Workflow
1.  Player 1 [Host/Defender] 
             defendCity(proof, cityId)
             - Chooses an Army (Starting a Game)
             - Verify if it is 0,1, or 2 (choice -> Private) 
             - Hash the choice with player secret -> let hash = Poseidon.hash([choice,salt]) 
             - mapping(cityId => hash)
             

2. Player 2 [Joiner/Attacker] 
             attackCity(cityId, armyType -> (0,1,2))
             - verify // on chain 
             - This is completely public and on-chain 
             - store timestamp 

3. Player 1 [Defender] - Reveals his attack 
            finalize()
            - This battle is on-chain or circuit? 

4. Player 2 can call forfiet() if Player 1 does not reveal in timestamp + 24hrs        


- We just Keep a leaderboard of wins 
 - Players can only attack once in 24 hrs 


