## Key Points Explained
- Multi-Stage Build:
  This Dockerfile is divided into two stages: build and runtime. 
  This approach allows us to separate the environment needed to build the application from the environment needed to run the application.
  As a result, the final image is smaller because it doesn't include build tools and source code, only the runtime environment and the built application.

- Layer Caching:
  Docker builds images in layers. By copying the .csproj files and running dotnet restore before copying the rest of the source code,
  we ensure that Docker can reuse the cached layers for the restore step as long as the project files don't change. This optimization speeds up the build process.

- Alpine Images:
  Both stages of the build use Alpine images, which are minimal and lightweight, significantly reducing the final image size. 
  This choice is ideal for production environments where efficiency is key.

###############################################

## Build Stage
## This stage uses the .NET SDK to build the application (Development tools).
## We use an Alpine version for a smaller image size. The 'AS build' names this stage so we can refer to it later.
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

## Sets the working directory inside the Docker image for any subsequent COPY, RUN, and CMD commands.
WORKDIR /src

## Before copying the entire source, we utilize a .dockerignore file to exclude files not needed in the build context,
## such as local development configurations and dependencies that can be fetched.
## Copy csproj first to leverage Docker's layer caching. If no changes are detected in the csproj files,
## Docker will use the cached layer for the dotnet restore command, speeding up the build process.
## (Libraries & Dependencies)
COPY *.csproj .

## Restores the NuGet packages required by the project(s). This command benefits from caching if the csproj files haven't changed.
RUN dotnet restore

## Now, copy the rest of the source code into the image. Since this step is likely to change more frequently,
## it's placed after the restore step to ensure the cache is utilized effectively up until this point.
COPY . .

## Compiles the application, setting the configuration to Release and outputting the built files to /src/out.
## The --no-restore option is used because we've already restored the dependencies.
RUN dotnet publish -c Release -o /src/out --no-restore

## Runtime Stage
## This stage uses the .NET runtime, specifically an Alpine version for a smaller image size.
## This is where we prepare the environment to run the application, separate from the build environment.
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

## Again, sets the working directory inside the Docker image for any subsequent commands.
WORKDIR /app

## Informs Docker and readers that the container listens on port 8080 at runtime.
## This is more for documentation purposes, as it doesn't actually publish the port.
EXPOSE 8080

## Copy the built application files from the 'build' stage into this image.
## This is where multi-stage builds shine, as we only bring over the artifacts we need to run the application,
## leaving behind everything else related to building the app.
COPY --from=build /src/out .

## Sets the command to run the application when the container starts.
## Here, 'dotnet BlazorApp1.dll' tells Docker to execute our .NET application.
ENTRYPOINT ["dotnet", "BlazorApp1.dll"]