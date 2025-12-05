FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5244
ENV ASPNETCORE_URLS=http://+:5244

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .

FROM build as publish
RUN dotnet publish "TaxiMoWebAPI/TaxiMoWebAPI.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .

ENTRYPOINT ["dotnet","TaxiMoWebAPI.dll"]