import Rice.TemporalLog.TemporalLogComponent;
import Rice.TemporalLog.CapabilityTemporalLogAction;

UFUNCTION(Category = "Temporal Log")
UTemporalLogComponent StartTemporalLogging(AHazeActor Actor)
{
	UTemporalLogComponent Log = GetTemporalLog(Actor);
	if (Log != nullptr)
	{
		Log.SetLogEnabled(true);
	}
	else
	{
		Log = UTemporalLogComponent::GetOrCreate(Actor);

		for (auto ActionClass : UClass::GetAllSubclassesOf(UTemporalLogAction::StaticClass()))
		{
			auto Action = Cast<UTemporalLogAction>(NewObject(Log, ActionClass));
			Log.LogAction(Action);
		}

		Log.GetFrame();
	}
	return Log;
}

UFUNCTION(Category = "Temporal Log")
void StopTemporalLogging(AHazeActor Actor)
{
	UTemporalLogComponent Log = GetTemporalLog(Actor);
	if (Log != nullptr)
		Log.SetLogEnabled(false);
}

UFUNCTION(Category = "Temporal Log")
void DeleteTemporalLog(AHazeActor Actor)
{
	UTemporalLogComponent Log = GetTemporalLog(Actor);
	if (Log != nullptr)
	{
		Log.SetLogEnabled(false);
		Log.DestroyComponent(Log);
	}
}

UFUNCTION(Category = "Temporal Log")
UTemporalLogComponent GetTemporalLog(AHazeActor Actor)
{
	return UTemporalLogComponent::Get(Actor);
}

UFUNCTION(Category = "Temporal Log")
void GetAllTemporalLogs(TArray<UTemporalLogComponent>& OutLogs)
{
	OutLogs.Reset();

	TArray<AHazeActor> Actors;
	GetAllActorsOfClass(Actors);

	for (auto Actor : Actors)
	{
		auto Comp = UTemporalLogComponent::Get(Actor);
		if (Comp != nullptr)
			OutLogs.Add(Comp);
	}
}

const FConsoleCommand Command_LogPlayers("Haze.TemporalLog.LogPlayers", n"LogPlayers");
void LogPlayers(const TArray<FString>& Args)
{
	StartTemporalLogging(Game::GetMay());
	StartTemporalLogging(Game::GetCody());
}

const FConsoleCommand Command_StopAll("Haze.TemporalLog.StopAll", n"StopAll");
void StopAll(const TArray<FString>& Args)
{
	TArray<UTemporalLogComponent> Logs;
	GetAllTemporalLogs(Logs);

	for (auto Log : Logs)
		Log.SetLogEnabled(false);
}