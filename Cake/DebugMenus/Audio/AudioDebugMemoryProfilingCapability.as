import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
// Goes through all levels and sends the data to the log and wwise
class UAudioDebugMemoryProfilingCapability : UHazeDebugCapability
{
	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsValue(n"EnableAudioMemoryProfiling", 1, "Goings through ALL checkpoints in the game", true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	int PreviousDebugValue = 0;
	TArray<FString> LevelsWithProgressPoints;
	TArray<FHazeProgressPoint> CurrentProgressPoints;

	// Only run setup if it ever gets enabled.
	bool bHasRunSetup = false;
	bool bWasInLoadingScreen = false;
	int ActiveLevelGroup = -1;
	int ActiveProgressPoint = -1;
	float TimerDuration = 10;
	float InitialLoadTimer = 0;

	// ShortId's are based on hashing of names, and the master bus should never change it's name.
	private uint MasterBusId = 3803692087;
	private bool bIsProfilerEnabled = false;
	// So we actually get some profiler data.
	void RegisterProfilerCallbacks(bool bEnable)
	{
		if (bEnable == bIsProfilerEnabled)
			return;

		bIsProfilerEnabled = bEnable;

		if (bIsProfilerEnabled)
		{
			Audio::UnregisterResourceMonitoring();
			Audio::UnregisterBusMetering(MasterBusId);
		}
		else if (!bIsProfilerEnabled)
		{
			Audio::RegisterResourceMonitoring();
			Audio::RegisterBusMetering(MasterBusId);
		}

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int NewValue = 0;
		if (!Owner.GetDebugValue(n"EnableAudioMemoryProfiling", NewValue) || NewValue == 0)
		{
			RegisterProfilerCallbacks(false);
			return;
		}
		RegisterProfilerCallbacks(true);

		if (Game::IsInLoadingScreen())
			return;

		if (!bHasRunSetup)
		{
			bHasRunSetup = true;
			LevelsWithProgressPoints = Progress::GetLevelsWithProgressPoints();
		}

		if (CurrentProgressPoints.Num() > 0)
		{
			float Progress = Progress::GetLevelLoadProgress(CurrentProgressPoints[ActiveProgressPoint].InLevel);
			if (Progress != 0)
				return;
		}

		if (InitialLoadTimer >= 0)
		{
			InitialLoadTimer -= DeltaTime;
			PrintToScreen("Loading next checkpoint in: " + InitialLoadTimer, 0);
			return;
		}

		PostMemoryLoad();

		if (ActiveLevelGroup == -1 || (CurrentProgressPoints.Num() > 0 && ActiveProgressPoint == CurrentProgressPoints.Num()-1))
		{
			//Reset
			if (ActiveLevelGroup <= LevelsWithProgressPoints.Num())
			{
				++ActiveLevelGroup;
				auto NewProgressPoints = Progress::GetProgressPointsInLevel(LevelsWithProgressPoints[ActiveLevelGroup]);
				CurrentProgressPoints.Reset();
				
				TSet<FString> Filter;
				for(FHazeProgressPoint Point : NewProgressPoints)
				{
					if (Filter.Contains(Point.InLevel))
						continue;
					
					CurrentProgressPoints.Add(Point);
					Filter.Add(Point.InLevel);
				} 
				LoadCheckpoint(0);
			}
		}
		else 
		{
			int NewIndex = FMath::Min(++ActiveProgressPoint, CurrentProgressPoints.Num()-1);
			LoadCheckpoint(NewIndex);
		}
	}

	private void PostMemoryLoad()
	{
		if (ActiveLevelGroup == -1 || ActiveProgressPoint == -1)
			return;

		FAudioProfilingResourceMonitorData ProfilingData = Audio::GetProfilingData();
		FAudioProfilingMemoryData MemoryData = Audio::GetProfilingMemoryData();

		FString LevelName = CurrentProgressPoints[ActiveProgressPoint].InLevel;
		FString CheckpointName = CurrentProgressPoints[ActiveProgressPoint].Name;

		uint64 MediaMemoryInMB = (uint64(MemoryData.uUsed) / (1024*1024));
		FString Memory = "" + MediaMemoryInMB + " MB" + 
			"in Level: " + LevelName + 
			" at Checkpoint: " + CheckpointName;
		Audio::OutputErrorToWwiseAuthoring(Memory, nullptr);
		
		FString Message ="";
		Message = "PhysicalVoices: " + ProfilingData.PhysicalVoices;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);

		Message =  "VirtualVoices: " + ProfilingData.VirtualVoices;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);

		Message =  "TotalVoices: " + ProfilingData.TotalVoices;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);
		
		Message =  "NumberOfActiveEvents: " + ProfilingData.NumberOfActiveEvents;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);

		Message =  "TotalCPU: " + ProfilingData.TotalCPU;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);

		Message =  "PluginCPU: " + ProfilingData.PluginCPU;
		Memory += "\n " +  Message;
		Audio::OutputErrorToWwiseAuthoring(Message, nullptr);

		// Let's print it to a file as well.
		Audio::OutputProfilerDataToFile(Memory);
	}

	private void LoadCheckpoint(int Index)
	{
		ActiveProgressPoint = Index;
		FString Checkpoint = CurrentProgressPoints[Index].InLevel+"##"+CurrentProgressPoints[Index].Name;
		Progress::RestartFromProgressPoint(Checkpoint, false);
		InitialLoadTimer = TimerDuration;
	}
}	