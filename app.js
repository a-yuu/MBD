const express = require('express')
const bodyParser = require('body-parser')
const cookieParser = require ('cookie-parser')

// https://id.javascript.info/modules-intro
// Ngambil code file lain (konsep: JavaScript modules (CommonJS))
const db = require('./services/connection')
const {response} = require('./utils/response')
const {jwt} = require('./services/jwt')
const {authRouter} = require('./routers/auth')
const {nonAuthRouter} = require('./routers/non-auth')


// https://expressjs.com/en/starter/hello-world.html
const app = express()

// Middleware (app.use)
// bodyParser: nge-parsing body dari request client
// .json(): karena yang mau kita parse dalam format JSON
app.use(bodyParser.json())

app.use(cookieParser())

app.use(nonAuthRouter)

app.use((request, response, next) => {
    const token = request.cookies.token
    const payload = jwt.verify(token)

    if (!payload) {
        response
            .status(401)
            .json({
                message: "Unauthorized",
            })

        return
    }

    // biar payload bisa dipanggil di endpoint lain
    response.locals.payload = payload

    next()
})

app.use(authRouter)

app.listen(3000, () => {
    console.log('server listening on port 3000')
})