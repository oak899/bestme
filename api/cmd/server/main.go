package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/oak899/growthos/api/handlers"
	"github.com/oak899/growthos/api/store"
)

func main() {
	addr := env("ADDR", "127.0.0.1:8090")
	dbPath := env("DB_PATH", "/opt/bestme/data/bestme.db")
	webDist := env("WEB_DIST", "/opt/bestme/web")

	if err := os.MkdirAll(filepath.Dir(dbPath), 0o755); err != nil {
		log.Fatal(err)
	}

	st, err := store.Open(dbPath)
	if err != nil {
		log.Fatal(err)
	}
	defer st.Close()
	handlers.DB = st

	mux := http.NewServeMux()
	mux.HandleFunc("/api", handlers.WithAuth(apiHandler))
	mux.HandleFunc("/api/", handlers.WithAuth(apiHandler))

	if info, err := os.Stat(webDist); err == nil && info.IsDir() {
		fs := http.FileServer(http.Dir(webDist))
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if strings.HasPrefix(r.URL.Path, "/api") {
				apiHandler(w, r)
				return
			}
			path := filepath.Join(webDist, filepath.Clean("/"+r.URL.Path))
			if _, err := os.Stat(path); os.IsNotExist(err) || strings.HasSuffix(r.URL.Path, "/") {
				http.ServeFile(w, r, filepath.Join(webDist, "index.html"))
				return
			}
			fs.ServeHTTP(w, r)
		})
		log.Printf("serving web from %s", webDist)
	} else {
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if strings.HasPrefix(r.URL.Path, "/api") {
				apiHandler(w, r)
				return
			}
			http.NotFound(w, r)
		})
	}

	log.Printf("GrowthOS listening on %s (db=%s)", addr, dbPath)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func apiHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	handlers.Router(w, r)
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
