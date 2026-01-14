FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5244
ENV ASPNETCORE_URLS=http://+:5244
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["TaxiMoWebAPI/TaxiMoWebAPI.csproj", "TaxiMoWebAPI/"]
COPY ["TaxiMo.Services/TaxiMo.Services.csproj", "TaxiMo.Services/"]
COPY ["TaxiMo.Model/TaxiMo.Model.csproj", "TaxiMo.Model/"]
RUN dotnet restore "TaxiMoWebAPI/TaxiMoWebAPI.csproj"
COPY . .
WORKDIR "/src/TaxiMoWebAPI"
RUN dotnet build "TaxiMoWebAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "TaxiMoWebAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "TaxiMoWebAPI.dll"]
