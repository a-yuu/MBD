const express = require('express')
const bodyParser = require('body-parser')

// https://id.javascript.info/modules-intro
// Ngambil code file lain (konsep: JavaScript modules (CommonJS))
const db = require('./services/connection')
const response = require('./utils/response')


// https://expressjs.com/en/starter/hello-world.html
const app = express()

// Middleware (app.use)
// bodyParser: nge-parsing body dari request client
// .json(): karena yang mau kita parse dalam format JSON
app.use(bodyParser.json())



// Handle request yang methodnya POST (konsep: HTTP method)
app.post('/RegisterUser', (req, res) => {
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

app.post('/login', (req, res) => {
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
                if (err.sqlState === '45000') {
                    return response(400, null, err.sqlMessage, res);
                }

                console.error(err);
                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat login', res);
            }

            // `results` hasil dari query
            return response(201, results, 'Login Berhasil', res);
        }
    );
});



app.post('/InsertStokVitamin', (req, res) => {
    const { ID_Vitamin, ID_User, Tanggal_Masuk_Vitamin, Jumlah_Stok_Vitamin } = req.body;
    if ( !ID_User || !ID_Vitamin || !Tanggal_Masuk_Vitamin || !Jumlah_Stok_Vitamin ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InsertStokVitamin(?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ ID_Vitamin, ID_User, Tanggal_Masuk_Vitamin, Jumlah_Stok_Vitamin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error(err);

                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat menambahkan vitamin', res);
            }

            // `results` hasil dari query
            return response(201, results, 'stok vitamin berhasil ditambahkan', res);
        }
    );
});

app.post('/InputReminderVitamin', (req, res) => {
    const { ID_User, ID_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder } = req.body;
    if ( !ID_User || !ID_Vitamin || !Tanggal_Reminder || !Waktu_Reminder || !Pesan_Reminder || !Status_Reminder ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InputReminderVitamin(?,?,?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ ID_User, ID_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error(err);

                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat menambahkan vitamin', res);
            }

            // `results` hasil dari query
            return response(201, results, 'reminder berhasil ditambahkan', res);
        }
    );
});

app.post('/InputReminderPengingatStokVitamin', (req, res) => {
    const { ID_Stok_Vitamin, ID_User, Pesan_Reminder, Batas_Minimum_Stok_Vitamin } = req.body;
    if ( !ID_User || !ID_Stok_Vitamin || !Pesan_Reminder || !Batas_Minimum_Stok_Vitamin ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL InputReminderPengingatStokVitamin(?,?,?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ ID_Stok_Vitamin, ID_User, Pesan_Reminder, Batas_Minimum_Stok_Vitamin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error(err);

                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat menambahkan vitamin', res);
            }

            // `results` hasil dari query
            return response(201, results, 'reminder stok berhasil ditambahkan', res);
        }
    );
});

app.post('/SetLowStockNotification', (req, res) => {
    const { ID_User, ID_Stok_Vitamin, Batas_Minimum_Stok } = req.body;
    if ( !ID_User || !ID_Stok_Vitamin || !Batas_Minimum_Stok ){
        return response(400, null, 'Semua field harus diisi', res);
    }

    db.query(
        // `?` merepresentasikan banyaknya argument yang dapat diterima oleh sebuah procedure
        "CALL SetLowStockNotification(?,?,?)",
        // Array itu berisi data yang akan di-pass ke procedure
        [ ID_Stok_Vitamin, ID_User, Batas_Minimum_Stok_Vitamin ],
        // Callback, err dan results
        (err, results) => {
            // ketika terjadi error `err` bakal keisi message error
            // (konsep: truthy and falsy)
            if (err) {
                console.error(err);

                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat menambahkan vitamin', res);
            }

            // `results` hasil dari query
            return response(201, results, 'set reminder stok berhasil ditambahkan', res);
        }
    );
});

const port = 3000
app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
})