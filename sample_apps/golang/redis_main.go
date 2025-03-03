package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"math/rand"
	"os"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

func generateRandomData(dataSize uint) string {
	charset := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	dataSize = dataSize * 1024 // converting to bytes from Kb
	randomData := make([]byte, dataSize)

	for i := range randomData {
		randomData[i] = charset[rand.Intn(len(charset))]
	}

	return string(randomData)
}

func populateSet(setName string, ctx context.Context, rClient *redis.Client, wg *sync.WaitGroup) {
	defer wg.Done()

	// Add 10,000 elements to the set
	for i := 0; i < 10000; i++ {
		member := generateRandomData(10) // 10KB data
		err := rClient.SAdd(ctx, setName, member).Err()
		if err != nil {
			fmt.Printf("Error adding to set %s: %v\n", setName, err)
		} else {
			if i%1000 == 0 { // Print progress every 1000 elements
				fmt.Printf("Added %d elements to set %s\n", i, setName)
			}
		}
	}
	fmt.Printf("Completed populating set %s\n", setName)
}

func intersectSets(ctx context.Context, rClient *redis.Client) {
	fmt.Println("Starting set intersection...")

	// Create slice of all set names
	sets := make([]string, 10)
	for i := 0; i < 10; i++ {
		sets[i] = fmt.Sprintf("set%d", i)
	}

	iteration := 1
	for {
		startTime := time.Now()

		// Perform intersection
		result, err := rClient.SInter(ctx, sets...).Result()
		if err != nil {
			fmt.Printf("Error performing intersection: %v\n", err)
			return
		}

		duration := time.Since(startTime)
		fmt.Printf("Iteration %d: Intersection found %d elements, took %.2f seconds\n",
			iteration, len(result), duration.Seconds())

		// If operation takes less than 2 seconds, break
		if duration.Seconds() > 2.0 {
			fmt.Printf("Latency increased above 2 seconds. Exiting.\n")
			break
		}

		iteration++
	}
}

func main() {
	rdb := redis.NewClient(&redis.Options{
		Addr: "master.skyforge-cmd.a433yr.aps1.cache.amazonaws.com:6379",
		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
	})

	ctx := context.Background()

	// Check if we should only perform intersection
	if len(os.Args) > 1 && os.Args[1] == "intersect" {
		intersectSets(ctx, rdb)
		return
	}

	// Create 10 sets with 10,000 elements each
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		setName := fmt.Sprintf("set%d", i)
		go populateSet(setName, ctx, rdb, &wg)
	}

	wg.Wait()
	fmt.Println("All sets populated!")
}
