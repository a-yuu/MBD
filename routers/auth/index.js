const express = require('express')

const router = express.Router()
const db = require('../../services/connection')
const response = require('../../utils/response')

router.delete("/logout", (_request, response) => {
    response.cookie(
        "token",
        "",
        {
            maxAge: 0
        }
    )

    response.json({
        message: "Berhasil logout"
    })
})

router.get('/users', (req, res) => {
    console.log("titid")
    // Panggil procedure yang fungsinya untuk nampilin semua users
    db.query("CALL GetAllUsers()", (err, results) =>{
        if (err) {
            console.error(err);
            return response(500, null, 'Terjadi kesalahan saat mengambil daftar users', res);
        }

        return response(201, results, 'Data users berhasil diambil', res);
    })
})

router.post('/AddVitamin', (req, res) => {
    const { Nama_Vitamin, Jenis_Vitamin, Waktu_Penggunaan, Tanggal_Konsumsi, Jumlah_Konsumsi, Status_Konsumsi } = req.body;
    // if (!Nama_Vitamin || !Jenis_Vitamin || !Waktu_Penggunaan || !Tanggal_Konsumsi || !Status_Konsumsi){
    //     return response(400, null, 'Semua field harus diisi', res);
    // }
    // console.log('azargantenk')
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
                console.error(err);

                // (konsep: HTTP response status)
                return response(500, null, 'Terjadi kesalahan saat menambahkan vitamin', res);
            }

            // `results` hasil dari query
            return response(201, results, 'Vitamin berhasil ditambahkan', res);
        }
    );
});


module.exports.authRouter = router