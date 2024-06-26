const http = require("http");
const express = require("express");
const app = express();
const session = require("express-session");
const cookieParser = require("cookie-parser");
const passport = require("passport");
const { localAuth, jwtAuth } = require("./auth/index");
const cors = require("cors");
const { swaggerUi, specs } = require("./swagger");

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static("uploads"));
app.use(cors());
app.use(
	session({
		secret: "secret",
		resave: true,
		saveUninitialized: false,
		maxAge: new Date(Date.now() + 3600000),
	}),
);
app.use((err, req, res, next) => {
	// Handle the error
	console.log(err);
	res.status(500).json({ error: "Internal Server Error" });
});

app.use(async function(req, res, next) {
	try {
		res.locals.user = req.user || null;
		next();
	} catch (error) {
		next(error);
	}
});
app.use(passport.initialize());
app.use(passport.session());
jwtAuth(passport);
localAuth(passport);

app.use("/", require("./routes/index"));

app.use("/api/v1/user", require("./routes/api/user"));
app.use("/api/v1/chat", require("./routes/api/chat"));
app.use("/api/v1/house", require("./routes/api/house"));
app.use("/api/v1/favorite", require("./routes/api/favorite"));
app.use("/api/v1/reservation", require("./routes/api/reservation"));
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(specs));

http.createServer(app).listen(4500, () => {
	console.log("server run on port 4500");
});
