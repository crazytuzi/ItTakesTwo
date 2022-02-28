import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseCrumbVelocityPredictionCapability;

class AMicrophoneChaseVelocityPredictionTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeLazyPlayerOverlapComponent PlayerOverlap;
	default PlayerOverlap.ResponsiveDistanceThreshold = 5000.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Network::IsNetworked())
		{
			PlayerOverlap.OnPlayerBeginOverlap.AddUFunction(this, n"Handle_PlayerOverlapBegin");
			PlayerOverlap.OnPlayerEndOverlap.AddUFunction(this, n"Handle_PlayerOverlapEnd");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_PlayerOverlapBegin(AHazePlayerCharacter Player)
	{
		UMicrophoneChaseVelocityPredictionComponent VelPredComp = UMicrophoneChaseVelocityPredictionComponent::Get(Player);
		if(VelPredComp != nullptr)
		{
			VelPredComp.DisableVelocityPrediction();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_PlayerOverlapEnd(AHazePlayerCharacter Player)
	{
		UMicrophoneChaseVelocityPredictionComponent VelPredComp = UMicrophoneChaseVelocityPredictionComponent::Get(Player);
		if(VelPredComp != nullptr)
		{
			VelPredComp.EnableVelocityPrediction();
		}
	}
}
