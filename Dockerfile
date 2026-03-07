FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/ProductAPI/ProductAPI.csproj", "src/ProductAPI/"]
COPY ["tests/ProductAPI.Tests/ProductAPI.Tests.csproj", "tests/ProductAPI.Tests/"]
COPY ["ProductAPI.sln", "."]
RUN dotnet restore "ProductAPI.sln"
COPY . .
WORKDIR "/src/src/ProductAPI"
RUN dotnet publish "ProductAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
RUN groupadd -r appgroup && useradd -r -g appgroup -s /bin/false appuser
WORKDIR /app
COPY --from=build --chown=appuser:appgroup /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
USER appuser
ENTRYPOINT ["dotnet", "ProductAPI.dll"]
