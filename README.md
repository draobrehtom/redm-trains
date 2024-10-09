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
