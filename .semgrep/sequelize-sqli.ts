// Semgrep rule test for sequelize-raw-query-string-concat. Run: semgrep --test .semgrep/
// An annotation on the line above a match asserts the expected result.

// ruleid: sequelize-raw-query-string-concat
models.sequelize.query(`SELECT * FROM Users WHERE email = '${email}'`, { model: UserModel })

// ruleid: sequelize-raw-query-string-concat
models.sequelize.query('SELECT * FROM x WHERE a = ' + input)

// ok: sequelize-raw-query-string-concat
models.sequelize.query('SELECT * FROM Products WHERE name LIKE :q', { replacements: { q } })

// ok: sequelize-raw-query-string-concat
models.sequelize.query(`SELECT * FROM Products ORDER BY name`)
