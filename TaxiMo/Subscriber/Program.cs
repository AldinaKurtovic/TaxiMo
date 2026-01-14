using EasyNetQ;
using TaxiMo.Model.Messages;

Console.WriteLine("TaxiMo RabbitMQ Subscriber starting...");

try
{
    var connectionString = Environment.GetEnvironmentVariable("RABBITMQ_CONNECTIONSTRING") 
        ?? "host=localhost";
    Console.WriteLine($"Connecting to RabbitMQ: {connectionString.Replace("password=", "password=***")}");
    using var bus = RabbitHutch.CreateBus(connectionString);

    await bus.PubSub.SubscribeAsync<RideCreated>(
        "taximo_ride_subscriber",
        async message =>
        {
            Console.WriteLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Ride {message.RideId} was created for user {message.RiderId} and driver {message.DriverId}.");
        });

    Console.WriteLine("Subscribed to RideCreated messages. Waiting for messages...");
    Console.WriteLine("Press Ctrl+C to exit.");
    
    // Keep the application running
    using var cancellationTokenSource = new CancellationTokenSource();
    Console.CancelKeyPress += (_, e) =>
    {
        e.Cancel = true;
        cancellationTokenSource.Cancel();
    };

    await Task.Delay(Timeout.Infinite, cancellationTokenSource.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("\nShutting down gracefully...");
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
    Console.WriteLine("Press any key to exit...");
    Console.ReadKey();
}
