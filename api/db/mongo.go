package db

import (
	"context"
	"os"
	"sync"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	client     *mongo.Client
	clientOnce sync.Once
	clientErr  error
)

func Client() (*mongo.Client, error) {
	clientOnce.Do(func() {
		uri := os.Getenv("MONGODB_URI")
		if uri == "" {
			clientErr = mongo.ErrClientDisconnected
			return
		}
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		client, clientErr = mongo.Connect(ctx, options.Client().ApplyURI(uri))
	})
	return client, clientErr
}

func Collection(name string) (*mongo.Collection, error) {
	c, err := Client()
	if err != nil {
		return nil, err
	}
	return c.Database("bestme").Collection(name), nil
}
