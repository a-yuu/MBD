const express = require('express')
const bodyParser = require("body-parser")

const {jwt} = require('../../services/jwt')
const db = require('../../services/connection')
const {sqlClientErrors} = require ('../../utils/sqlClientErrors')
const response = require('../../utils/response')

const router = express()

router.use(bodyParser.json())

// Handle request yang methodnya POST (konsep: HTTP method)
router.post('/RegisterUser', (req, res) => {
    const { Nama_User, username, Password, is_admin } = req.body; // (konsep: destructuring object JS)

    // ! || buat ngecek kalau semisal ada request yang kurang
    if (!Nama_User || !username || !Password || is_admin === undefined){
        // (konsep: HTTP response status)
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        return response(400, null, 'Semua field harus diisi', res);
    }
    
    // Query ke DB
    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL RegisterUser(?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [Nama_User, username, Password, is_admin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                if (err.sqlState === '45000') {
                    return response(400, null, err.sqlMessage, res);
                }

                console.error(err);
                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat mendaftar', res);
            }

            // `results` hasil dari query
            return response(201, results, 'Pendaftaran Berhasil', res);
        }
    );
});

router.post('/login', (req, res) => {
    const { username, Password } = req.body; // (konsep: destructuring object JS)

    // ! || buat ngecek kalau semisal ada request yang kurang
    if (!username || !Password ){
        // (konsep: HTTP response status)
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        return response(400, null, 'Semua field harus diisi', res);
    }
    
    // Query ke DB
    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL login(?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [username, Password ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                const sqlErrorCode = err.sqlState

                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response(500, null, 'Internal Server Error', res);
                }

                console.error(err);
                // (konsep: HTTP response status)
                return response(400, null, err.sqlMessage, res);
                }

            const queryResult = results[0][0]
            console.log(results[0][0])

            res.cookie(
                "token",
                jwt.sign(queryResult),
                {
                    maxAge: 3_600 * 1000
                }
            )

            // `results` hasil dari query
            return response(201, results, 'Login Berhasil', res);
        }
    );
});

router.post('/AddVitamin', (req, res) => {
    const { Nama_Vitamin, Jenis_Vitamin, Waktu_Penggunaan, Tanggal_Konsumsi, Jumlah_Konsumsi, Status_Konsumsi } = req.body;

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL AddVitamin(?,?,?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ Nama_Vitamin, Jenis_Vitamin, Waktu_Penggunaan, Tanggal_Konsumsi, Jumlah_Konsumsi, Status_Konsumsi ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error('SQL Error:', err);
                const sqlErrorCode = err.sqlState || err.code

                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response(400, null, err.sqlMessage, res);
                }

                // (konsep: HTTP response status)
                
                return response(500, null, 'Internal Server Error', res);
            }

            // `results` hasil dari query
            return response(201, results, 'Vitamin berhasil ditambahkan', res);
        }
    );
});

router.post('/InsertStokVitamin', (req, res) => {
    const { Nama_Vitamin, Tanggal_Masuk_Vitamin, Jumlah_Stok_Vitamin } = req.body;
    if ( !Nama_Vitamin || !Tanggal_Masuk_Vitamin || !Jumlah_Stok_Vitamin ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InsertStokVitamin(?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ Nama_Vitamin, Tanggal_Masuk_Vitamin, Jumlah_Stok_Vitamin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error('SQL Error:', err);
                const sqlErrorCode = err.sqlState || err.code

                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response(400, null, err.sqlMessage, res);
                }

                // (konsep: HTTP response status)
                
                return response(500, null, 'Internal Server Error', res);
            }

            // `results` hasil dari query
            return response(201, results, 'stok vitamin berhasil ditambahkan', res);
        }
    );
});

router.post('/InputReminderVitamin', (req, res) => {
    const { username, Nama_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder } = req.body;
    if ( !username || !Nama_Vitamin || !Tanggal_Reminder || !Waktu_Reminder || !Pesan_Reminder || !Status_Reminder ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InputReminderVitamin(?,?,?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ username, Nama_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error('SQL Error:', err);
                const sqlErrorCode = err.sqlState || err.code

                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response(400, null, err.sqlMessage, res);
                }

                // (konsep: HTTP response status)
                
                return response(500, null, 'Internal Server Error', res);
            }

            // `results` hasil dari query
            return response(201, results, 'reminder berhasil ditambahkan', res);
        }
    );
});

router.post('/InputReminderPengingatStokVitamin', (req, res) => {
    const { Nama_Vitamin, username, Pesan_Reminder, Batas_Minimum_Stok_Vitamin } = req.body;
    if ( !Nama_Vitamin || !username || !Batas_Minimum_Stok_Vitamin ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InputReminderPengingatStokVitamin(?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ Nama_Vitamin, username, Pesan_Reminder, Batas_Minimum_Stok_Vitamin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error('SQL Error:', err);
                const sqlErrorCode = err.sqlState || err.code

                if (!sqlClientErrors.includes(sqlErrorCode)) {
                    return response(400, null, err.sqlMessage, res);
                }

                // (konsep: HTTP response status)
                
                return response(500, null, 'Internal Server Error', res);
            }


            // `results` hasil dari query
            return response(201, results, 'reminder stok berhasil ditambahkan', res);
        }
    );
});

module.exports.nonAuthRouter = router
