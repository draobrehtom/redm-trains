1) Баг с направлением поезда. Когда игрока подключился, то поезд изменил своё направление.

Central Union Express stopped at Saint Denis Station (S)
Date: 2023-10-26 14:43:27

murzea_alin @David.M42 jumped into virtual world #1
Date: 2023-10-26 16:43:??

Central Union Express stopped at Saint Denis Station (R)
Date: 2023-10-26 14:43:40

Central Union Express stopped at Emerald Station (R)
Date: 2023-10-26 14:48:24

Это значит, что если поезд заспаунить до или после Saint Dennis, значит он поменяет своё напраление. Скорее всего поезд был заспаунен на ЖД Emerald по ошибке. А должен был быть заспаунен на ЖД Сейнт Дени.

2) Далее я пробовал перезапускать скрипт (спаунив поезд в Saint Denis), я находился там-же. Другой игрок, изначальный владелец, находился в Валентайн. Так вот, когда я делал перезапуски/телепорт в другой мир у меня то-ли появлялся поезд без вагонов, то ли это был дубликат поезда.

Что нужно сделать - удаление всех поезд через сервер, при остановке скрипта.


3) Поезда продублировались когда:
- Поезд был у Валентайна, а я был на Rigs st.. У Валентайна находились два игрока.
Я подлетел к Валентайну, поезд начал дёргаться. Далее он остановился. Далее поезд телепортировался чуть вперёд.
Далее поезда продублировались (может быть и до этого они уже были продублированы). 
Так-же в логах виднеется как один из игроков телепортировался в другой измерение.



---- Фиксы:
Убрал удаление поезда при миграции, добавил логи. Теперь поезд должен плавно мигрировать с игрока на игрока, а если вдруг он телепортируется, тогда будет пересоздан. Возможны проблемы с пропаданием вагонов.

Заново записал маршрут поезда, на этот раз с указателем направления. Так-же при ре-спауне поезд я всегда указываю его направление.

# -- Дальнешее наблюдение:

Поезд постоянно менял владельца и телепортировался
Координаты поезда: vector3(890.5318, 763.1472, 107.6146)
Телепортировался в vector3(2659.662, -429.2704, 42.57434)

[x] Добавлены логи координат игроков, чтобы лучше понять где находятся игроки и как это вляет на миграцию
[x] Добавлены логи количества вагонов у поезда


# 29.10.2023 Поезд пропал и не спаунится:
Поезд остановился на координатах: vector3(1303.029, 758.7805, 95.5663)  (Пред. остановка в дискорд логах Heartland Oil Fields)

Так-же при этом симуляция тоже не работает. Симуляция: {vector3(1301.362, 759.663, 94.76925), 0},

TODO: Ошибка похоже в том, что игрок, на котором создавался поезд, отключился не отправив ответ серверу.

[       script:trains] Server Trains    {"train1":3}
[       script:trains] --------]
[       script:trains] - Train owner quit from Routing Bucket #1
[       script:trains] (Loop) Stopped (not existing or migrated):       train1
[       script:trains] (Loop) Train migrated:   true
[       script:trains] - Waiting for train deletion
[       script:trains] [x] entityRemoved:       train1  3       [x] entityOwner:        train1  5       MrDingo
[       script:trains] [x] First entity owner same as current one       5       MrDingo
[       script:trains] - Previous owner doesnt exist / not in routing bucket #1
[       script:trains] - No other players found for recreation of train
[       script:trains] - Train recreation started       false
[       script:trains] - Waiting for new players connecting to server
[       script:trains] - Some player connected -  recreate train        train1  5       MrDingo
[       script:trains] ... Get handle from net id       23
[       script:trains] [--------
[       script:trains] Created train by player  5       MrDingo TrainId and NetId       train1  23
[       script:trains] Client trains    [{"netId":23}]
[       script:trains] Server Trains    {"train1":23}
[       script:trains] --------]
[       script:trains] - Train owner quit from Routing Bucket #1
[       script:trains] (Loop) Stopped (not existing or migrated):       train1
[       script:trains] (Loop) Train migrated:   true
[       script:trains] - Waiting for train deletion
[       script:trains] [x] entityRemoved:       train1  23      [x] entityOwner:        train1  5       MrDingo
[       script:trains] [x] First entity owner same as current one       5       MrDingo
[       script:trains] - Previous owner doesnt exist / not in routing bucket #1
[       script:trains] - No other players found for recreation of train
[       script:trains] - Train recreation started       false
[       script:trains] - Waiting for new players connecting to server
[     script:zconcept] Disconnected [✓]:       MrDingo
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[     script:zconcept] Disconnected [✓]:       Max Mullen
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[script:discord-roles] Discord roles synced for player   7
[     script:zconcept] Disconnected [✓]:       Max Mullen
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[script:discord-roles] Discord roles synced for player   8
[ citizen-server-impl] sync thread hitch warning: timer interval of 116 milliseconds
[     script:zconcept] Disconnected [✓]:       Max Mullen
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[script:discord-roles] Discord roles synced for player   9
[     script:zconcept] Disconnected [✓]:       Max Mullen
[ citizen-server-impl] sync thread hitch warning: timer interval of 139 milliseconds
[ citizen-server-impl] server thread hitch warning: timer interval of 161 milliseconds
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[script:discord-roles] Discord roles synced for player   10
[     script:zconcept] Disconnected [✓]:       Max Mullen
[     script:zconcept] Connecting [𐄂]:        Max Mullen
[     script:zconcept] Connected [✓]:  Max Mullen
[script:discord-roles] Discord roles synced for player   11
[     script:zconcept] Disconnected [✓]:       Max Mullen
[     script:zconcept] Connecting [𐄂]:        Haezakmi
[     script:zconcept] Connecting [𐄂]:        Haezakmi
[     script:zconcept] Connected [✓]:  Haezakmi
[script:discord-roles] Discord roles synced for player   12
[       script:trains] - Some player connected -  recreate train        train1  12      Haezakmi
[ citizen-server-impl] server thread hitch warning: timer interval of 189 milliseconds
[     script:zconcept] Connecting [𐄂]:        Mateus Kiev

[x] Добавил отслеживание бага
[x] Перезапустил скрипт, ведётся дальнешее наблюдение

```lua

CreateThread(function()
    while true do
        Wait(5000)
        if getSomePlayer() then
            for trainId,netId in pairs(Trains) do
                if not DoesEntityExist(NetworkGetEntityFromNetworkId(netId)) then
                    sendToDiscordDebugInfo(nil, ('**[POSSIBLE BUG]** Train **%s** does not exist, despite that there are player candidates for train creation.'):format(trainId))
                end
            end
        end
    end
end)
```


# Наблюдение о пропадающих вагонах

1. Добавленные логи о количестве вагонов не срабатывают на новом владельце поезда (false).
Это происходит из-за того, что старый владелец ушёл в другой мир, а поезд при этом был пересоздан.


2. Когда я владея поездом выхожу из мира в другой (он мигигрует на игрока), затем - обратно, поезд спаунится без вагонов.
