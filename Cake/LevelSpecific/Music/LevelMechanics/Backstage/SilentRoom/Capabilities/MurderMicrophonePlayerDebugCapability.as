import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophonePlayerDebugCapability : UHazeDebugCapability
{
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler KillClosestSnakeHandler = DebugValues.AddFunctionCall(n"KillClosestSnake", "Kill Closest Snake");
		
		KillClosestSnakeHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"MurderMicrophone");
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

	UFUNCTION()
	void KillClosestSnake()
	{
		AMurderMicrophone TargetSnake = GetClosestSnake();

		if(TargetSnake != nullptr)
		{
			NetDestroyMurderMicrophone(TargetSnake);
		}
	}

	UFUNCTION(NetFunction)
	private void NetDestroyMurderMicrophone(AMurderMicrophone MurderMicrophone)
	{
		MurderMicrophone.DebugDestroyMurderMicrophone();
	}

	AMurderMicrophone GetClosestSnake() const
	{
		TArray<AActor> ListOfActors;
		Gameplay::GetAllActorsOfClass(AMurderMicrophone::StaticClass(), ListOfActors);

		float DistanceCurrentSq = Math::MaxFloat;
		AActor TargetSnake = nullptr;

		for(AActor SnakeActor : ListOfActors)
		{
			AMurderMicrophone TempSnake = Cast<AMurderMicrophone>(SnakeActor);
			if(TempSnake == nullptr)
				continue;

			if(TempSnake.IsSnakeDestroyed())
				continue;

			const float DistanceSq = Owner.ActorLocation.DistSquared(SnakeActor.ActorLocation);
			if(DistanceSq < DistanceCurrentSq)
			{
				DistanceCurrentSq = DistanceSq;
				TargetSnake = SnakeActor;
			}
		}

		AMurderMicrophone MurderMicrophone = Cast<AMurderMicrophone>(TargetSnake);
		return MurderMicrophone;
	}
}
