const response = (statusCode, data, message, res) => {
    // Gunakan .status() untuk set kode HTTP
    res.status(statusCode).json({
        payload: data,
        message,
        // metadata: {
        //     prev: "",
        //     next: "",
        //     current: "",
        // },
    });
};

module.exports = response;
