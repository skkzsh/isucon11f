package main

import (
	"github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"

	sqltrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/database/sql"
	sqlxtrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/jmoiron/sqlx"
)

func GetDB(batch bool) (*sqlx.DB, error) {
	mysqlConfig := mysql.NewConfig()
	mysqlConfig.Net = "tcp"
	mysqlConfig.Addr = GetEnv("MYSQL_HOSTNAME", "127.0.0.1") + ":" + GetEnv("MYSQL_PORT", "3306")
	mysqlConfig.User = GetEnv("MYSQL_USER", "isucon")
	mysqlConfig.Passwd = GetEnv("MYSQL_PASS", "isucon")
	mysqlConfig.DBName = GetEnv("MYSQL_DATABASE", "isucholar")
	mysqlConfig.Params = map[string]string{
		"time_zone": "'+00:00'",
	}
	mysqlConfig.ParseTime = true
	mysqlConfig.MultiStatements = batch

	sqltrace.Register("mysql", &mysql.MySQLDriver{}, sqltrace.WithServiceName(ServiceName))
	return sqlxtrace.Open("mysql", mysqlConfig.FormatDSN())
	// return sqlx.Open("mysql", mysqlConfig.FormatDSN())
}
