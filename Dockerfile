FROM golang:1.18 as builder

WORKDIR /go/src/github.com/ribbybibby/testy

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o testy .

FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /go/src/github.com/ribbybibby/testy/testy testy

USER 65532:65532

ENTRYPOINT ["/testy"]
