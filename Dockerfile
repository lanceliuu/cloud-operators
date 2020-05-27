# Build the manager binary
FROM golang:1.14-buster as builder

# Copy in the go src
WORKDIR /go/src/github.com/ibm/cloud-operators
COPY .  /go/src/github.com/ibm/cloud-operators

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags netgo -ldflags "-w" -a -o ibm-cloud-operator github.com/ibm/cloud-operators/cmd/manager

# Copy the controller-manager into a thin image
FROM us.icr.io/coligo-baseimage/ubi8-minimal:latest
COPY --from=builder /go/src/github.com/ibm/cloud-operators/ibm-cloud-operator /ibm-cloud-operator
ENTRYPOINT ["/ibm-cloud-operator"]
