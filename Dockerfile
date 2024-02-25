# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src

# Utilize .dockerignore to prevent copying unnecessary files
# Copy csproj first to leverage Docker cache
COPY *.csproj .
RUN dotnet restore

# Copy the rest of the source code
COPY . .
RUN dotnet publish -c Release -o /src/out --no-restore

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

# Expose port 8080 for the application
EXPOSE 8080

# Copy built files from the previous stage
COPY --from=build /src/out .

# Set the entry point for the application
ENTRYPOINT ["dotnet", "BlazorApp1.dll"]