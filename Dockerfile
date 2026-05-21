# STEP 1: The Build Environment
# We use the heavy .NET 10 SDK image to compile the code
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Pro-Tip: We copy ONLY the project files first. 
# This caches the NuGet packages so builds are lightning fast if you only change code.
COPY ["Domain/Domain.csproj", "Domain/"]
COPY ["Application/Application.csproj", "Application/"]
COPY ["Infrastructure/Infrastructure.csproj", "Infrastructure/"]
COPY ["Presentation/Presentation.csproj", "Presentation/"]
COPY ["Tests/Tests.csproj", "Tests/"]

# Restore all the dependencies
RUN dotnet restore "Presentation/Presentation.csproj"

# Now copy the rest of the actual C# code
COPY . .
WORKDIR "/src/Presentation"

# Publish the compiled app to the /app/publish folder
RUN dotnet publish "Presentation.csproj" -c Release -o /app/publish /p:UseAppHost=false

# STEP 2: The Production Environment
# We switch to the lightweight ASP.NET runtime image to keep the final file size tiny
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Open port 8080 for web traffic
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Start the application
ENTRYPOINT ["dotnet", "Presentation.dll"]
