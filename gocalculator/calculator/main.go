package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/gorilla/mux"
	"go.elastic.co/apm"
	"go.elastic.co/apm/module/apmgoredisv8"
	"go.elastic.co/apm/module/apmhttp"
	"go.elastic.co/apm/module/apmgorilla"
	_ "expvar"
)





var redisClient *redis.Client
var logger *log.Logger

type Operation struct {
	Message  string  `json:"message"`
	Operand1 float64 `json:"operand1"`
	Operand2 float64 `json:"operand2"`
	Operator string  `json:"operator"`
	Result   float64 `json:"result"`
}





type logWrapper struct {
	*log.Logger
}

func (l *logWrapper) Debugf(format string, args ...interface{}) {
	l.Printf("[DEBUG] "+format, args...)
}

func (l *logWrapper) Errorf(format string, args ...interface{}) {
	l.Printf("[ERROR] "+format, args...)
}

func (l *logWrapper) Infof(format string, args ...interface{}) {
	l.Printf("[INFO] "+format, args...)
}

func (l *logWrapper) Warnf(format string, args ...interface{}) {
	l.Printf("[WARN] "+format, args...)
}




func main() {


	tracer := apm.DefaultTracer



	router := mux.NewRouter()
	apmgorilla.Instrument(router)



	router.HandleFunc("/calc/{operand1}/{operator}/{operand2}", handleCalc).Methods("GET")
	router.HandleFunc("/history", handleHistory).Methods("GET")
        router.HandleFunc("/health", handleHealthCheck).Methods("GET")



	redisClient = redis.NewClient(&redis.Options{
		Addr: "redis-b1b1cbb75d29dbd4.elb.us-east-1.amazonaws.com:6379",
		DB:   0,
		DialTimeout: 1 * time.Second,
		ReadTimeout: 5 * time.Second,
		WriteTimeout: 1 * time.Second,
	})
	redisClient.AddHook(apmgoredisv8.NewHook())




	logFile, err := os.OpenFile("calculator.log", os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0644)
        if err != nil {
                log.Fatalf("Failed to create or open log file: %v", err.Error())
        }

	logFileAPM, err := os.OpenFile("apm.log", os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0644)
        if err != nil {
                log.Fatalf("Failed to create or open apm log file: %v", err.Error())
        }

	loggerAPM := log.New(logFileAPM, "APM: ", log.Ldate|log.Ltime)
	wrappedApmLogger := &logWrapper{loggerAPM}

	apm.DefaultTracer.SetLogger(wrappedApmLogger)

	logger = log.New(logFile, "APP: ", log.Ldate|log.Ltime)

	logger.Println("Trying to start server on port 8080")





	logger.Fatal(http.ListenAndServe(":8080", apmhttp.Wrap(router, apmhttp.WithTracer(tracer))))
}






func handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status": "OK",
	})
}


func handleCalc(w http.ResponseWriter, r *http.Request) {

	tx := apm.TransactionFromContext(r.Context())
	defer tx.End()



	vars := mux.Vars(r)
	operand1, operator, operand2 := vars["operand1"], vars["operator"], vars["operand2"]


	op1, err := stringToFloat(operand1)
	if err != nil {
		logger.Printf("Invalid operand 1, error: %v\n", err.Error())
		http.Error(w, "Invalid operand 1", http.StatusBadRequest)
		return
	}

	op2, err := stringToFloat(operand2)
	if err != nil {
		logger.Printf("Invalid operand 2, error: %v\n", err.Error())
		http.Error(w, "Invalid operand 2", http.StatusBadRequest)
		return
	}

	var result float64


	switch operator {
	case "+":
		result = op1 + op2
	case "-":
		result = op1 - op2
	case "*":
		result = op1 * op2
	case "div":

		if op2 == 0 {
			errorMessage := "Cannot divide by zero"
			logger.Println(errorMessage)
			http.Error(w, errorMessage, http.StatusBadRequest)
			return
		}

		result = op1 / op2

	default:

		errorMessage := "Invalid operator"
		logger.Println(errorMessage)
		http.Error(w, errorMessage, http.StatusBadRequest)
		return
	}



	saveOperationMessage := "operation saved successfully"

	operation := Operation{saveOperationMessage, op1, op2, operator, result}

	err = saveOperation(operation)
	if err != nil {
		logger.Printf("Failed to save operation in redis: %v\n", err.Error())
		saveOperationMessage = "operation could not be saved"
	}

	operation.Message = saveOperationMessage

	logger.Printf("Calculation:  %f %s %f = %f, %v\n", op1, operator, op2, result, saveOperationMessage)

	json.NewEncoder(w).Encode(operation)
}

func handleHistory(w http.ResponseWriter, r *http.Request) {

	tx := apm.TransactionFromContext(r.Context())
	defer tx.End()



	operations, err := getOperations()
	if err != nil {
		logger.Printf("Failed to get operations: %v\n", err.Error())
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(operations)
}

func stringToFloat(s string) (float64, error) {
	var f float64
	_, err := fmt.Sscan(s, &f)
	if err != nil {
		logger.Printf(err.Error())
		return 0, err
	}
	return f, nil
}

func saveOperation(operation Operation) error {

	operationJSON, err := json.Marshal(operation)
	if err != nil {
		return err
	}
	err = redisClient.LPush(redisClient.Context(), "operations", string(operationJSON)).Err()
	if err != nil {
		return err
	}
	return nil
}

func getOperations() ([]Operation, error) {

	operationStrings, err := redisClient.LRange(redisClient.Context(), "operations", 0, -1).Result()
	if err != nil {
		return nil, err
	}

	var operations []Operation

	for _, opStr := range operationStrings {
		var op Operation
		err := json.Unmarshal([]byte(opStr), &op)
		if err != nil {
			return nil, err
		}
		operations = append(operations, op)
	}

	return operations, nil
}
