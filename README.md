# Server-side implemenation of trains for RedM

The script allows you to have a constant train running on your server even if you have 0 players on your server.
When there are no players on server or train is not in the scope of player - the train trajectory is simulate via `server/simulation.lua`.
Train entity migration is handled via `server/sv_main.lua`.

On client-side train is created without ped-driver, to avoid additional problems with ped-driver entity-migration

Code is highly unorganized - it's in a state of research and testing phase and was never finished as a final product. You can find some piece of codes here and there, even there some observation notes about entity-migration during the development of script. 

Since I left my attempts in finishing this my will is to share it to the public and hope this repository might be helpful for enthusiasts who are trying to make fully-working server-side trains for RedM.  

I might be return to this proejct some day, but so far I'm waiting at lease a minimal feedback from RedM developers about the [train sync issue](https://github.com/citizenfx/fivem/issues/2630).


![image](https://github.com/user-attachments/assets/37889c22-73b1-4898-b8ca-d3893babda4e)

![image](https://github.com/user-attachments/assets/1831700f-9b27-40a9-9593-a9f978dc596a)


## Some features:

- Discord notifications about train stops:

![image](https://github.com/user-attachments/assets/a0696276-f0fb-4a36-a235-82f9c6d862b4)

- Discord debug notifications about train entity migration:

![image](https://github.com/user-attachments/assets/abb86b18-22c6-441b-9abf-a6b6906b0e93)

## Why trains break under OneSync (RedM), and what this script does about it

Findings from reading the RedM/FiveM source (`citizenfx/fivem`), not guesses:

1. **The server does not parse the RDR3 train sync node.** `SyncTrees_RDR3.h` declares `CTrainGameStateDataNode { }` empty; every train-aware helper in `ServerGameState` (`IterateTrainLink`, chain relevancy, chain migration, carriage recursion in `DeleteEntity`, `SET_ENTITY_ORPHAN_MODE`) is `#ifdef STATE_FIVE`. To the server a train is N unrelated entities. `DELETE_TRAIN` and `SET_ENTITY_ORPHAN_MODE` touch only the entity you pass.
2. **Migration teleports the train to track node 0.** FiveM fixed this for GTA V (`fix(net/five): correct train track node on ownership change`, `CloneObjectManager.cpp`, `CTrain::SetTrainCoord(train, -1, -1)` on `ChangeOwner`). The code is compiled for RDR3 too but the fix is under `#ifdef GTA_FIVE`. The "static migration points" in the observations are node 0 of the respective tracks in `trains*.dat`.
3. **Migrated trains lose their carriages.** `PatchTrainConfigCrash.cpp` (RedM, 2023): a cloned train has train config index `0xFF`; `RequestTrainCarriageAssets` used to crash on it, now returns `false`. Carriages are never requested on the new owner.
4. **OneSync migrates by distance, on the server, without asking the client.** `ServerGameState.cpp`: when an entity leaves its owner's culling radius `wantsReassign` is set and the first client that has the entity in range takes it (`ReassignEntity`), no `CanPassControl` involved. `PREVENT_NETWORK_ID_MIGRATION` only blocks the game's own proximity hand-over (client path through `CanPassControl`). Owner disconnect reassigns to the nearest player (`MoveEntityToCandidate`).

What the script does now:

- the client waits for `HasTrainLoaded`, then reports the net id of **every car**; the server protects and deletes cars one by one;
- `SET_ENTITY_DISTANCE_CULLING_RADIUS` (`Config.CullingRadius`, whole map) on every car keeps the train inside the owner's range, so the server never triggers a hand-over;
- `PREVENT_NETWORK_ID_MIGRATION` on every car blocks the client-side hand-over;
- `SET_ENTITY_ORPHAN_MODE(DeleteOnOwnerDisconnect)` on every car: when the creator leaves, the train is deleted server-side and recreated on another player (existing recreation + server simulation), instead of arriving on a new owner without carriages at track node 0;
- any owner change that still gets through is treated as a migration and the train is recreated.
