# Наблюдения

1. Поезд создался у Коли, он создался на сервере, но у меня его на карте не видно.

Т.е. поезда на отдалённом расстоянии существуют только на одном клиенте


Далее я решил посмотреть на поезд, но он оказался без вагонов.
Вывод №1: если поезд мигрирует на другого игрока, тогда он остаётся без вагонов

Далее Люман вышел и поезда удалились. 
Вывод №2: если игрок владеющий (заспаунивший) поездами отключается от сервера, тогда поезда удаляются.
Entity owner -1

Так-же нужно быть осторожным при получении сущности с нетАйди - нужно ожидать значение т.к. изначальное может быть нулём.



Заметки по миграции поезда:

1) Если поезд мигрирует, то он спаунится в другом месте, чуть дальше, чем если бы поезд создавался сразу на моём клиенте.

Нормальный спаун:
vector3(2729.5883, -1459.727, 45.903129)

Спаун при миграции:
vector3(2489.029, -1481.154, 46.14247)
Этот спаун статичный. Используется как начальная точка при миграции поезда.


Есть и другой статичный спаун:
Нормальный спаун:
(-158.177, 635.38629, 113.52156), -- test
Спаун при миграции:
vector3(2660.743, -453.6898, 43.20664)
Он как будто зеркально противоположный (относительно Saint Denis)

То есть идёт выбор между этими двумя статичными спаунами - который ближе. Там спаунится поезд, а затем отттуда в сторону нужного
спауна поезд начинает свой путь (по идее в ту сторону куда будет коороче ехать).

Есть и другие точки:
Спаун: vector3(-1090.563, -588.4188, 81.372642)
Миграция: vector3(967.6385, -902.2346, 67.68607)

Спаун: vector3(-318.5835, -339.5699, 89.8374)
Миграция: vector3(541.0817, -524.6379, 77.05151)

Спаун: vector3(-504.0194, -432.0699, 82.54294)
Миграция: vector3(-650.6699, -509.1755, 77.53156)

2) Если смигрировавший поезд уезжает от меня, то он пропадает спустя какое-то расстояние (~440.0) (удаляется и не мигрирует).
Предпологаю, что поезд уходит из моего скоупа и не попадает в скоуп к другого игрока. Но если в отключусь от сервера, тогда поезд 
смигрирует к другому игроку.

3) Мои изначальные поезда (созданные на моём клиенте), вообще не удаляются/мигрируют - когда я летаю по крате в отдалённости от них. Видимо поезд не входит в скоуп других игроков, поэтому поезд остаётся на мне как далеко он бы не находился.

4) Если поезд мигрирует, то у него пропадают вагоны.

5) Странно, но сейчас переманил к себе моезд, далее отлетел от него на очень большое расстояние, но поезд до сих пор не пропал.
Как только я отключился от сервера, поезд вернулся к прежнему владельцу.

6) Поезд остановился на координатах vector3(2883.35, -1121.894, 45.23658) и не едет дальше


# Какие проблемы предстоит решить:

1) Пофиксить пропадающие вагоны поезда при миграции
2) Пофиксить рассинхрон расположения поезда при миграции
3) Отобразить блипы поездов на карте всем игрокам, даже если поезд не существует на их стороне
4) Сделать респаун поезда, если он не смигрировал, а просто удалился
5) Сделать закольцовку поезда по всей траектории (чтобы он не останавливался в конце дороги)
6) Пофиксить само-миграцию поезда / рассинхрон позиции при переключении RoutingBucket (пока что это выглядит как обычная миграция, только на самого себя)



Заметка:
1) Когда я находился на сервере один и менял виртуальный мир, то поезда оставилсь серверно существовать.
На моё карте они не отображались, если я скакнул в мир, а если вернулся - поезда поменяли свою позицию, далеко телепортировались.
Как если бы они совершили миграцию - в том случае поезда тоже меняют свою позицию (так-же теряют вагоны).

2) Когда я находился на сервере один, был в виртуальном мире, а поезда - в нулевом и существовали на мне,
подкючился Люман. Поезда у него не были видны, хотя он находился в нулевом мире.

3) Когда я отключился, тогда поезда удалились (не смигрировали на Люмана).

4) Когда я меняю виртуальный (владея поездами) и находясь рядом с Люманом, то поезда остаются на мне.
TODO: Создать поезда, получить подтверждение от Люмана о создании, телепортнуться в другой мир и отлететь от Люмана.

5) Когда я создаю поезда на свой стороне, однако один из поездов находится:
- в зоне Люмана
- ближе к Люману
- максимально близко к Люман
- не в моём скоупе
То поезд мигрирует на Люмана, а затем сразу удаляется. 

6) Миграция происходит только по оси XY (grid)



Dist between prev owner and train:    417.2717590332  (424)
Dist between new owner and train:     69.005905151368
Dist between owners:  348.55853271484



Протестить:
1) Смигрированный поезд уезжает из скоупа владельца (424.0):
- Не попадает в скоуп другого игрока
-- Удаляется [x]
-- Продолжает движение []
-- Телепортируется []
- Попадает в скоуп другого игрока:
-- Удаляется []
-- Продолжает движение [x]
-- Телепортируется [x?]

2) Оригинальный поезд уезжает из скоупа владельца (442.0)
- Не попадает в скоуп другого игрока
-- Удаляется []
-- Продолжает движение [x]
-- Телепортируется []
- Попадает в скоуп другого игрока
-- Удаляется []
-- Продолжает движение [x]
-- Телепортируется [x?]


# Part 2

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
