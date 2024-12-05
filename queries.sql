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

        INSERT INTO USER (
                Nama_User, 
                username,
                Password, 
                Tanggal_Daftar,
                is_admin)
        VALUES (
                p_Nama_User, 
                p_username,
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
        in p_Password VARCHAR(255)
)
BEGIN
        DECLARE EXIT HANDLER for SQLEXCEPTION
        BEGIN
                ROLLBACK;
                resignal;
        end;
       
        START TRANSACTION;

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
	        RESIGNAL; 
	    END;
	
	    START TRANSACTION;
	
	    IF p_Jumlah_Konsumsi IS NULL THEN
	        SET p_Jumlah_Konsumsi = 1;
	    END IF;
	
	    IF p_Status_Konsumsi NOT IN ('Terkonsumsi', 'Belum Terkonsumsi') THEN
	        SIGNAL SQLSTATE 
	        	'45000'
	        SET 
	       		message_text = 'Status konsumsi harus "Terkonsumsi" atau "Belum Terkonsumsi"';
	    END IF;
	
	    IF p_Jenis_Vitamin NOT IN ('Tablet', 'Sirup') THEN
	        SIGNAL SQLSTATE 
	        	'45000'
	        SET 
	       		message_text = 'Jenis vitamin harus "Tablet" atau "Sirup"';
	    END IF;
	
	    INSERT INTO VITAMIN (
	        Nama_Vitamin, 
	        Jenis_Vitamin, 
	        Waktu_Penggunaan,
	        Tanggal_Konsumsi, 
	        Jumlah_Konsumsi, 
	        Status_Konsumsi
	    ) 
	    VALUES (
	        p_Nama_Vitamin,
	        p_Jenis_Vitamin,
	        p_Waktu_Penggunaan,
	        p_Tanggal_Konsumsi,
	        p_Jumlah_Konsumsi,
	        p_Status_Konsumsi
	    );
	
	    COMMIT; 
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE InsertStokVitamin (
		in p_Nama_Vitamin varchar (100),
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
       
        IF p_Pesan_Reminder IS NULL OR TRIM(p_Pesan_Reminder) = '' THEN
                SET p_Pesan_Reminder = 'Yuk, jangan lupa minum vitaminnya!';
        END IF;

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
        IN p_Nama_Vitamin VARCHAR(100),
        IN p_username VARCHAR(100),
        IN p_Pesan_Reminder TEXT, 
        IN p_Batas_Minimum_Stok_Vitamin INT
        ) 
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
                SET p_Pesan_Reminder = 'Stok vitaminmu tinggal dikit nih! Jangan lupa minum isi ulang, ya!';
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
        IN username INT, 
        IN Nama_Vitamin INT, 
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
        IN p_username INT
        ) 
BEGIN 
        DECLARE EXIT HANDLER FOR sqlexception
        
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

-- procedure baru
-- panggil view dalam procedure baru
