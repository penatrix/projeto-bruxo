-- Conta de desenvolvimento. Rode com `make seed`.
-- Idempotente: pode rodar quantas vezes quiser.
--
-- Login: admin / admin   Personagem: Deus (group_id 6 = god)
--
-- NUNCA use isto num servidor exposto na internet.

INSERT INTO accounts (name, password, type)
VALUES ('admin', SHA1('admin'), 5)
ON DUPLICATE KEY UPDATE password = VALUES(password), type = VALUES(type);

-- posx/posy/posz em 0/0/7 fazem o personagem nascer no templo da town_id 1.
INSERT INTO players (name, group_id, account_id, level, vocation,
                     health, healthmax, mana, manamax,
                     town_id, posx, posy, posz, conditions, cap)
SELECT 'Deus', 6, a.id, 100, 4,
       1000, 1000, 1000, 1000,
       1, 0, 0, 7, '', 500
FROM accounts a
WHERE a.name = 'admin'
ON DUPLICATE KEY UPDATE group_id = VALUES(group_id), level = VALUES(level);
