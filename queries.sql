drop database if exists vitamine;

create database vitamine;

use vitamine;

-- create table

CREATE TABLE USER (
    ID_User INT AUTO_INCREMENT PRIMARY KEY,
    Nama_User VARCHAR(255) not null,
    username VARCHAR(100) unique NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Tanggal_Daftar DATE NOT NULL,
    is_admin BOOLEAN NOT NULL
);

CREATE TABLE VITAMIN (
    ID_Vitamin INT AUTO_INCREMENT PRIMARY KEY,
    ID_User INT,
    Nama_Vitamin VARCHAR(100) NOT NULL,
    Jenis_Vitamin VARCHAR(50) NOT NULL,
    Waktu_Penggunaan TIME,
--     1 untuk fleksibelitas, jadi kalo user ga masukin jumlah vitamin yang diminum berapa, otomatis dihitung 1 sama aplikasi
    Jumlah_Konsumsi INT NOT NULL DEFAULT 1,
    Status_Konsumsi ENUM('Terkonsumsi', 'Belum Terkonsumsi') NOT NULL,
    Tanggal_Konsumsi DATE NOT NULL,
    FOREIGN KEY (ID_User) REFERENCES USER(ID_User)
);

-- CREATE TABLE KONSUMSI (
--     ID_Konsumsi INT AUTO_INCREMENT PRIMARY KEY,
--     ID_User INT,
--     ID_Vitamin INT,
--     Tanggal_Konsumsi DATE NOT NULL,
--     Waktu_Konsumsi TIME,
--     Jumlah_Konsumsi INT NOT NULL,
--     Status_Konsumsi ENUM('Terkonsumsi', 'Belum_Terkonsumsi') NOT NULL,
--     FOREIGN KEY (ID_User) REFERENCES USER(ID_User),
--     FOREIGN KEY (ID_Vitamin) REFERENCES VITAMIN(ID_Vitamin)
-- );

CREATE TABLE STOK_VITAMIN (
    ID_Stok_Vitamin INT AUTO_INCREMENT PRIMARY KEY,
    ID_Vitamin INT,
    ID_User INT,
    Tanggal_Masuk_Vitamin DATE NOT NULL,
    Jumlah_Stok_Vitamin INT NOT NULL,
    FOREIGN KEY (ID_Vitamin) REFERENCES VITAMIN(ID_Vitamin),
    FOREIGN KEY (ID_User) REFERENCES USER(ID_User)
);

CREATE TABLE REMINDER_MINUM_VITAMIN (
    ID_Reminder INT AUTO_INCREMENT PRIMARY KEY,
    ID_User INT,
    ID_Vitamin INT,
    Tanggal_Reminder DATE NOT NULL,
    Waktu_Reminder TIME NOT NULL,
    Pesan_Reminder TEXT,
    Status_Reminder ENUM('Sudah Minum', 'Belum Minum') NOT NULL,
    FOREIGN KEY (ID_User) REFERENCES USER(ID_User),
    FOREIGN KEY (ID_Vitamin) REFERENCES VITAMIN(ID_Vitamin)
);

CREATE TABLE REMINDER_PENGINGAT_STOK_VITAMIN (
    ID_Pengingat_Stok_Vitamin INT AUTO_INCREMENT PRIMARY KEY,
    ID_Stok_Vitamin INT,
    ID_User INT,
    Pesan_Reminder TEXT,
    Batas_Minimum_Stok_Vitamin INT NOT NULL,
    FOREIGN KEY (ID_Stok_Vitamin) REFERENCES STOK_VITAMIN(ID_Stok_Vitamin),
    FOREIGN KEY (ID_User) REFERENCES USER(ID_User)
);

-- create procedure

DELIMITER //
CREATE PROCEDURE RegisterUser(
        IN p_Nama_User VARCHAR(255),
        IN p_username VARCHAR(100),   
        IN p_Password VARCHAR(255),
        IN p_No_Telepon VARCHAR(15),
        IN p_is_admin BOOLEAN
        ) 
BEGIN 
        DECLARE userCount INT; 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
        ROLLBACK; 
        RESIGNAL; 
END;
        START TRANSACTION;
        if (p_username is null or length(p_username) < 1) then
                signal sqlstate
                '45000'
                set
                message_text = 'Nama tidak boleh kosong';
        end if;

        if (length(p_Password) < 8) then
                signal sqlstate
                '45000'
                set
                message_text = 'Panjang password minimal 8 karakter';
        end if;

        if (length(p_No_Telepon) < 10 or length(p_No_Telepon) > 15) then
                signal sqlstate 
                        '45000'
                set
                        message_text = 'Nomor telepon harus terdiri dari 10-15 digit';
        end if;

        if ((p_No_Telepon) NOT REGEXP '^[0-9]+$') then
                signal sqlstate 
                        '45000'
                set
                        message_text = 'Nomor telepon hanya boleh terdiri dari angka';
        end if;
        --     1 = simbol untuk cek keberadaan data, memakai 1 karena kita cuma butuh kolom no telp
        IF EXISTS (SELECT 1 FROM USER WHERE No_Telepon = NEW.No_Telepon) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Nomor telepon sudah terdaftar. Gunakan nomor lain.';
        END IF;

        INSERT INTO USER (
                Nama_User, 
                username, 
                No_Telepon, 
                Password, 
                Tanggal_Daftar,
                is_admin)
        VALUES (
                p_Nama_User, 
                p_username, 
                p_No_Telepon, 
                sha2(p_Password, 256), 
                CURDATE(), 
                FALSE
                ); 
        COMMIT; 
END//
DELIMITER ;

DELIMITER //
CREATE procedure login(
        in p_username VARCHAR(100),
        in p_Password VARCHAR(255),
)
BEGIN
        DECLARE EXIT HANDLER for SQLEXCEPTION
        BEGIN
                ROLLBACK;
        end;
        START TRANSACTION;
        
        if (length(p_username) <= 3) then
                signal sqlstate
                        '45000'
                set
                        message_text = 'Panjang username minimal 3 karakter';
        end if;

        if (length(p_Password) < 8) then
                signal sqlstate
                        '45000'
                set
                        message_text = 'Panjang password minimal 8 karakter';
        end if;

        if not exists(
                select
                        1
                from
                        USER
                where
                        username = p_username and password = sha2(p_Password, 256)
        ) then
                signal sqlstate
                        '45000'
                set
                        message_text = 'Username atau password salah';
        end if;

        select
                ID_User,
                Nama_User,
                username,
                is_admin
        from 
                USER
        where
                username = p_username and password = sha2(p_Password, 256);
        
        COMMIT;
end//
DELIMITER;

DELIMITER //
CREATE PROCEDURE GetAllUsers()
BEGIN
SELECT 
        ID_User,
        Nama_User,
        username,
        Tanggal_Daftar,
        is_admin
FROM USER;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE AddVitamin(
        IN p_Nama_Vitamin VARCHAR(100), 
        IN p_Jenis_Vitamin ENUM('Tablet', 'Sirup'),
        IN p_Waktu_Penggunaan TIME,
        IN p_Tanggal_Konsumsi DATE, 
        IN p_Jumlah_Konsumsi INT, 
        IN p_Status_Konsumsi ENUM('Terkonsumsi', 'Belum Terkonsumsi')
        ) 
BEGIN 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
        START TRANSACTION;

        if p_Jumlah_Konsumsi is null THEN
                set p_Jumlah_Konsumsi = 1;
        end if;

        if p_Status_Konsumsi not in ('Terkonsumsi', 'Belum Terkonsumsi') then
                signal sqlstate
                        '45000'
                set 
                        message_text = 'status konsumsi harus "Terkonsumsi" atau "Belum Terkonsumsi"';
        end if;

        if p_Jenis_Vitamin not in ('Tablet', 'Sirup') then
                signal sqlstate
                        '45000'
                set 
                        message_text = 'status konsumsi harus "Tablet" atau "Sirup"';
        end if;

        START TRANSACTION;

        INSERT INTO VITAMIN (
                Nama_Vitamin, 
                Jenis_Vitamin, 
                Waktu_Penggunaan,
                Tanggal_Konsumsi, 
                Jumlah_Konsumsi, 
                Status_Konsumsi)
        VALUES (p_Nama_Vitamin,
                p_Jenis_Vitamin,
                p_Waktu_Penggunaan,
                p_Tanggal_Konsumsi,
                p_Jumlah_Konsumsi,
                p_Status_Konsumsi);

        COMMIT; 
END//
DELIMITER ;


-- DELIMITER //
-- CREATE PROCEDURE InsertKonsumsiData (IN p_ID_User INT, IN p_ID_Vitamin INT, IN p_Tanggal_Konsumsi DATE, IN p_Waktu_Konsumsi TIME, IN p_Jumlah_Konsumsi INT, IN p_Status_Konsumsi ENUM('Terkonsumsi', 'Belum_Terkonsumsi')) BEGIN DECLARE EXIT
-- HANDLER FOR
-- SQLEXCEPTION BEGIN
-- ROLLBACK; END;
-- START TRANSACTION;
-- INSERT INTO KONSUMSI (ID_User, ID_Vitamin, Tanggal_Konsumsi, Waktu_Konsumsi, Jumlah_Konsumsi, Status_Konsumsi)
-- VALUES (p_ID_User,
--         p_ID_Vitamin,
--         p_Tanggal_Konsumsi,
--         p_Waktu_Konsumsi,
--         p_Jumlah_Konsumsi,
--         p_Status_Konsumsi);
-- COMMIT; END//
-- DELIMITER ;

DELIMITER //
CREATE PROCEDURE InsertStokVitamin (
        IN p_ID_Vitamin INT, 
        IN p_ID_User INT, 
        IN p_Tanggal_Masuk_Vitamin DATE, 
        IN p_Jumlah_Stok_Vitamin INT
        ) 
BEGIN 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
START TRANSACTION;
        if p_Jumlah_Stok_Vitamin <= 0 then
        signal sqlstate
                '45000'
        set
                MESSAGE_TEXT = 'Jumlah stok vitamin harus lebih dari 0';
        end if;

        if p_Tanggal_Masuk_Vitamin > CURDATE() then
                signal sqlstate
                        '45000'
                set
                MESSAGE_TEXT = 'tanggal masuk vitamin tidak boleh lebih dari hari ini';
        end if;

INSERT INTO STOK_VITAMIN (
        ID_Vitamin, 
        ID_User, 
        Tanggal_Masuk_Vitamin, 
        Jumlah_Stok_Vitamin
        )
VALUES (
        p_ID_Vitamin,
        p_ID_User,
        p_Tanggal_Masuk_Vitamin,
        p_Jumlah_Stok_Vitamin
        );
        COMMIT; 
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE InputReminderVitamin (
        IN p_username VARCHAR(100), 
        IN p_Nama_Vitamin VARCHAR(100), 
        IN p_Tanggal_Reminder DATE, 
        IN p_Waktu_Reminder TIME, 
        IN p_Pesan_Reminder TEXT, 
        IN p_Status_Reminder ENUM('Sudah Minum', 'Belum Minum')) 
BEGIN 
        DECLARE v_ID_User INT;
        DECLARE v_ID_Vitamin INT;

        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
        START TRANSACTION;

        SELECT ID_User INTO v_ID_User
        FROM USER
        WHERE username = p_username;

        IF v_ID_User IS NULL THEN
                SIGNAL SQLSTATE 
                        '45000'
                SET 
                        MESSAGE_TEXT = 'Username tidak ditemukan';
        END IF;

        SELECT ID_Vitamin INTO v_ID_Vitamin
        FROM VITAMIN
        WHERE Nama_Vitamin = p_Nama_Vitamin;

        IF v_ID_Vitamin IS NULL THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Nama vitamin tidak ditemukan.';
        END IF;

        if p_Status_Reminder not in ('Sudah Minum', 'Belum Minum') then
                signal sqlstate
                        '45000'
                set 
                        message_text = 'status konsumsi harus "Sudah Minum" atau "Belum Minum"';
        end if;


        if p_Waktu_Reminder < '00:00:00' or p_Waktu_Reminder > '23:59:59' then
                signal sqlstate
                        '45000'
                set
                MESSAGE_TEXT = 'waktu reminder tidak valid';
        end if;

        INSERT INTO REMINDER_MINUM_VITAMIN (
                ID_User, 
                ID_Vitamin, 
                Tanggal_Reminder, 
                Waktu_Reminder, 
                Pesan_Reminder, 
                Status_Reminder
                )
        VALUES (
                v_ID_User,
                v_ID_Vitamin,
                p_Tanggal_Reminder,
                p_Waktu_Reminder,
                p_Pesan_Reminder,
                p_Status_Reminder);
        COMMIT; 
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE InputReminderPengingatStokVitamin (
        IN p_ID_Stok_Vitamin INT, 
        IN p_ID_User INT, 
        IN p_Pesan_Reminder TEXT, 
        IN p_Batas_Minimum_Stok_Vitamin INT) 
BEGIN 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
        START TRANSACTION;

        IF p_Batas_Minimum_Stok_Vitamin < 5 THEN
                SIGNAL SQLSTATE 
                        '45000'
                SET 
                        MESSAGE_TEXT = 'Batas minimum stok vitamin harus lebih dari atau sama dengan 5 tablet.';
        END IF;

        IF p_Pesan_Reminder IS NULL OR TRIM(p_Pesan_Reminder) = '' THEN
                SET p_Pesan_Reminder = 'Yuk, jangan lupa minum vitaminnya!';
        END IF;

        INSERT INTO REMINDER_PENGINGAT_STOK_VITAMIN (
                ID_Stok_Vitamin, 
                ID_User, 
                Pesan_Reminder, 
                Batas_Minimum_Stok_Vitamin
                )
        VALUES (
                p_ID_Stok_Vitamin,
                p_ID_User,
                p_Pesan_Reminder,
                p_Batas_Minimum_Stok_Vitamin);
        COMMIT; 
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE SetLowStockNotification(
        IN p_ID_User INT, 
        IN p_ID_Stok_Vitamin INT, 
        IN p_Batas_Minimum_Stok_Vitamin INT) 
BEGIN 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
        START TRANSACTION; 
        if STOK_VITAMIN <= p_Batas_Minimum_Stok_Vitamin THEN
                INSERT INTO REMINDER_PENGINGAT_STOK_VITAMIN (
                        ID_Stok_Vitamin, 
                        ID_User, 
                        Pesan_Reminder, 
                        Batas_Minimum_Stok_Vitamin
                )
                VALUES (
                        p_ID_Stok_Vitamin,
                        p_ID_User,
                        CONCAT('Stok vitaminmu tinggal sedikit, ayo beli lagi ya! Stok nya sisa ', p_Batas_Minimum_Stok),
                        p_Batas_Minimum_Stok_Vitamin
                ); 
        END IF;

        COMMIT; 
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE GetVitaminStockReport(
        IN p_ID_User INT
        ) 
BEGIN 
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN
                ROLLBACK; 
        END;
        START TRANSACTION;

        IF NOT EXISTS (
                SELECT 1 -- 1 nandain kalo data nya ada
                FROM STOK_VITAMIN sv 
                WHERE sv.ID_User = p_ID_User
        ) THEN
                SIGNAL SQLSTATE 
                        '45000'
                SET 
                        MESSAGE_TEXT = 'Tidak ada stok vitamin ditemukan untuk pengguna ini.';
        END IF;

        SELECT  v.Nama_Vitamin,
                sv.Jumlah_Stok_Vitamin,
                sv.Tanggal_Masuk_Vitamin
        FROM VITAMIN v
        JOIN STOK_VITAMIN sv ON v.ID_Vitamin = sv.ID_Vitamin
        WHERE sv.ID_User = p_ID_User;
        COMMIT; 
END//
DELIMITER ;

-- TRANSACTION
-- DELIMITER //
-- CREATE PROCEDURE InputVitaminData (IN p_Nama_User VARCHAR(100), IN p_Jenis_Kelamin ENUM('L', 'P'), IN p_Tanggal_Lahir DATE, IN p_No_Telepon VARCHAR(15), IN p_Password VARCHAR(255), IN p_Nama_Vitamin VARCHAR(100), IN p_Jenis_Vitamin VARCHAR(50), IN p_Waktu_Penggunaan TIME, IN p_Jumlah_Stok INT, IN p_Tanggal_Reminder DATE, IN p_Waktu_Reminder TIME, IN p_Jumlah_Konsumsi INT, IN p_Waktu_Konsumsi TIME, IN p_Status_Konsumsi ENUM('Belum_Terkonsumsi', 'Terkonsumsi')) BEGIN DECLARE v_ID_User INT DEFAULT 0; DECLARE v_ID_Vitamin INT DEFAULT 0; DECLARE EXIT
-- HANDLER FOR
-- SQLEXCEPTION BEGIN
-- ROLLBACK; END;
-- START TRANSACTION;
-- INSERT INTO USER (Nama_User,
--                   Jenis_Kelamin,
--                   Tanggal_Lahir,
--                   No_Telepon,
--                   Password,
--                   Tanggal_Daftar)
-- VALUES (p_Nama_User,
--         p_Jenis_Kelamin,
--         p_Tanggal_Lahir,
--         p_No_Telepon,
--         p_Password,
--         CURDATE());
-- SET v_ID_User = LAST_INSERT_ID();
-- INSERT INTO VITAMIN (Nama_Vitamin, Jenis_Vitamin, Waktu_Penggunaan, ID_User)
-- VALUES (p_Nama_Vitamin,
--         p_Jenis_Vitamin,
--         p_Waktu_Penggunaan,
--         v_ID_User);
-- SET v_ID_Vitamin = LAST_INSERT_ID();
-- INSERT INTO STOK_VITAMIN (ID_Vitamin, ID_User, Tanggal_Masuk_Vitamin, Jumlah_Stok_Vitamin)
-- VALUES (v_ID_Vitamin,
--         v_ID_User,
--         CURDATE(),
--         p_Jumlah_Stok);
-- INSERT INTO REMINDER_MINUM_VITAMIN (ID_User, ID_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder)
-- VALUES (v_ID_User,
--         v_ID_Vitamin,
--         p_Tanggal_Reminder,
--         p_Waktu_Reminder,
--         'Ingat untuk minum vitamin!',
--         'Belum_Minum');
-- INSERT INTO KONSUMSI (ID_User, ID_Vitamin, Tanggal_Konsumsi, Waktu_Konsumsi, Jumlah_Konsumsi, Status_Konsumsi)
-- VALUES (v_ID_User,
--         v_ID_Vitamin,
--         DATE_ADD(CURDATE(), INTERVAL 1 DAY),
--         p_Waktu_Konsumsi,
--         p_Jumlah_Konsumsi,
--         p_Status_Konsumsi);
-- COMMIT; END//
-- DELIMITER ;

-- create trigger

DELIMITER //
CREATE TRIGGER reminder_notification AFTER
INSERT ON VITAMIN
FOR EACH ROW BEGIN DECLARE reminder_date DATE; DECLARE reminder_time TIME;
SET reminder_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY);
SET reminder_time = NEW.Waktu_Penggunaan;
INSERT INTO REMINDER_MINUM_VITAMIN (ID_User, ID_Vitamin, Tanggal_Reminder, Waktu_Reminder, Pesan_Reminder, Status_Reminder)
VALUES (NEW.ID_User,
        NEW.ID_Vitamin,
        reminder_date,
        reminder_time,
        CONCAT('Ingat untuk minum ', NEW.Nama_Vitamin, ' pada ', reminder_time),
        'Belum_Minum'); END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER after_vitamin_consumption AFTER
UPDATE ON VITAMIN
FOR EACH ROW BEGIN IF NEW.Status_Konsumsi = 'Terkonsumsi'
AND OLD.Status_Konsumsi <> 'Terkonsumsi' THEN
UPDATE STOK_VITAMIN
SET Jumlah_Stok_Vitamin = Jumlah_Stok_Vitamin - NEW.Jumlah_Konsumsi
WHERE ID_Vitamin = NEW.ID_Vitamin
    AND ID_User = NEW.ID_User; END IF; END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER check_stok_vitamin AFTER
UPDATE ON STOK_VITAMIN
FOR EACH ROW BEGIN DECLARE batas_minimum INT; DECLARE pesan_reminder TEXT;
SET batas_minimum = 5; IF NEW.Jumlah_Stok_Vitamin < batas_minimum THEN
SET pesan_reminder = CONCAT('Stok vitamin ',
                                (SELECT Nama_Vitamin
                                 FROM VITAMIN
                                 WHERE ID_Vitamin = NEW.ID_Vitamin), 'vitamin kamu hampir habis! Segera tambah stok.');
INSERT INTO REMINDER_PENGINGAT_STOK_VITAMIN (ID_Stok_Vitamin, ID_User, Pesan_Reminder, Batas_Minimum_Stok_Vitamin)
VALUES (NEW.ID_Stok_Vitamin,
        NEW.ID_User,
        pesan_reminder,
        batas_minimum);
INSERT INTO DEBUG_LOG (Message)
VALUES ('Trigger dijalankan: Reminder ditambahkan.'); END IF; END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION IsReminderMissed(p_ID_User INT, p_ID_Vitamin INT) RETURNS BOOLEAN DETERMINISTIC BEGIN DECLARE missed_count INT;
SELECT COUNT(ID_Reminder) INTO missed_count FROM REMINDER_MINUM_VITAMIN
WHERE ID_User = p_ID_User
    AND ID_Vitamin = p_ID_Vitamin
    AND Status_Reminder = 'belum minum'; IF missed_count > 0 THEN RETURN TRUE; ELSE RETURN FALSE; END IF; END//
DELIMITER ;

-- create view

DELIMITER //
CREATE VIEW View_Detail_Vitamin_User AS
SELECT u.ID_User,
       u.Nama_User,
       v.Nama_Vitamin,
       v.Jenis_Vitamin,
       v.Tanggal_Konsumsi,
       v.Waktu_Penggunaan
FROM USER u
JOIN VITAMIN v ON u.ID_User = v.ID_User//
DELIMITER ;


DELIMITER //
CREATE VIEW LowStockVitamins AS
SELECT u.Nama_User,
       v.Nama_Vitamin,
       s.Jumlah_Stok_Vitamin,
       r.Batas_Minimum_Stok_Vitamin
FROM STOK_VITAMIN s
JOIN VITAMIN v ON s.ID_Vitamin = v.ID_Vitamin
JOIN USER u ON s.ID_User = u.ID_User
JOIN REMINDER_PENGINGAT_STOK_VITAMIN r ON s.ID_Stok_Vitamin = r.ID_Stok_Vitamin
WHERE s.Jumlah_Stok_Vitamin <= r.Batas_Minimum_Stok_Vitamin//
    DELIMITER ;


DELIMITER //
CREATE VIEW Laporan_Persediaan_Vitamin AS
SELECT v.Nama_Vitamin,
       sv.Jumlah_Stok_Vitamin,
       sv.Tanggal_Masuk_Vitamin
FROM STOK_VITAMIN sv
JOIN VITAMIN v ON sv.ID_Vitamin = v.ID_Vitamin//
DELIMITER ;

-- procedure baru
-- panggil view dalam procedure baru