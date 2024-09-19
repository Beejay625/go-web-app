# First stage: Build the Go application
FROM golang:1.21 AS build

# Set working directory
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy the source code to the container
COPY . ./

#build the go webapp
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o webapp .

#change the permission of the static directory to 755
RUN chmod -R 755 /app/static 

RUN chmod -R 755 /app/static

# Second stage: Hardened runtime environment
FROM gcr.io/distroless/base

# Create a non-root user with a limited home directory
USER nonroot:nonroot

# Copy the executable from the build stage
COPY --from=build /app/webapp /webapp

# Copy static files from the build stage
COPY --from=build /app/static /static

# Expose the port that the application listens on
EXPOSE 8080

# Add a health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl --fail http://localhost:8080/health || exit 1

# Use distroless's entrypoint to run the application with limited privileges
ENTRYPOINT ["/webapp"]

# Ensure no additional privileges are given to the container
CMD ["--no-new-privileges"]
