const mysql = require('mysql2')

// buat user baru, yang privilege-nya only execute
// caranya???

// create user 'ayu'@'localhost' identified by 'ayu123';
// grant execute on `vitamine`.* to 'ayu'@'localhost';
//                               ^
//                    All table -
// flush privilege;

const db = mysql.createConnection({
    host: "localhost",
    user: "ayu",
    password: "ayu123",
    database: "vitamine"
})

db.connect((err) => {
    if (err) {
        console.error('Koneksi ke database gagal:', err);
    } else {
        console.log('Koneksi ke database berhasil.');
    }
});

module.exports = db