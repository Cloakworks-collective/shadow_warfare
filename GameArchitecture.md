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



## Circuits
1. Validate army and store army hash on-chain
  - Why? ==> it makes the defender army private.
2. Report opponents attack 
  - Why? ==> 1. Because the player should still mask his defending army
             2. If the player defends his city then he doesn't need to change it and it should remain private
             3. If destroyed or forfeited the require defender to build again.


## Readme for Circuit Breaker Submission 
- Describe in details the game architecture.
  - The overall game mental image
    - It is continent that has many citites .i.e. players
    - They register new cities
    - They deploy defense armies
    - They different public attack armies
    - They attack other cities
    - They get points
    - This game might be a critieria for network airdrops etc...

  - The game state
    - The elements of the state.
    - What changes the state
    - The key concept on how to keep the game interesting and interactive
    - The security considerations on when to allow/prevent players to attack/reportAttack

  - The players
    - How to build
    - How to attack
    - What they can and can't do
  
  - The key importance of ZKP integration
    - explain public inputs
    - what ZKP mask privacy: army / battle
    - key factor for game state in general 
  
- Draw some graphs for the contracts, game state, and ZK proofs.

- What each function does, if it needs explanation. 
- Describe how the tests check and simulate a game.


- Add section and talk about what we spent and what hurdles we encountered
  - We got sick, accident
  - First time using noir 
  - First using foundry 
  - Challenges to test noir/solidity together
  - We have small experience in solidity development
    - We might have security vulnerabilities
    - etc... 

- Emphasize on how innovative the game is 
  - The architecture
  - What inspired us
  - Why using noir
  - We tried using sindri but the API for noir integration is not up to date.

- Describe why we chose to work on a game 
  - Scroll
  - ZK --> Noir
  - Sindri --> not encouraging
  - Background: Beginner devs


## Game Story 
- Explain the game logic following the readme
  - It is an innovative game 
  - Scroll enables scalability(lower gas fees) and privacy infrastructure(noir zk) for developing gaming Dapps
  - Walk through the game readme to explain the game mechanics. 
    - Sugar coated description of the functions, modifiers, enums, game state, etc...
  - Transition to the key importance of zk in the game
    - Walk through noir circuits
      - Explain what the circuits do
      - Explain how the assert game rules
      - Army validity
      - Off-chain attack report honesty
      - how public input take place(most of them from the contract, sometimes from the player)
        - from the player --> set up new defense army + battle result
        - the rest is from the contract 
  - At this you had explained the general scope of the game mechanincs and circuits
  - Describe some technical details walking through the AutoBattler contract.
- At the end take 10 seconds to say that unfortunately we tried to showcase game simulation tersts with noir_js or foundry API but nothing worked
  - following tutorial the APIs and npm packages weren't consistent 
  - we spent a lot of time, it was chaotic, nothing worked, nothing commited
- Show that you deployed error free contract 


