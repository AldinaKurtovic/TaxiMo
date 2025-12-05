FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Subscriber/Subscriber.csproj", "Subscriber/"]
COPY ["TaxiMo.Model/TaxiMo.Model.csproj", "TaxiMo.Model/"]
RUN dotnet restore "Subscriber/Subscriber.csproj"
COPY . .
WORKDIR "/src/Subscriber"
RUN dotnet build "Subscriber.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Subscriber.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY Subscriber/appsettings.json .
ENTRYPOINT ["dotnet", "Subscriber.dll"]
