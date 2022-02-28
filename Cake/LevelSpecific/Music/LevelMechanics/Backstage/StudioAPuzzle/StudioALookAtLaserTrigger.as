import Vino.Camera.Settings.CameraPointOfInterestBehaviourSettings;
class AStudioALookAtLaserTrigger : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UPROPERTY()
	AActor ConnectedFocusActor;

	AHazePlayerCharacter Player;
	bool bHasSetFocusPoint = false;

	bool bPOIisEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxOverlap");
		Box.OnComponentEndOverlap.AddUFunction(this, n"OnBoxEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ConnectedFocusActor == nullptr)
			return;

		if (Player.IsAnyCapabilityActive(n"CymbalShield") && !bPOIisEnabled)
		{
			bPOIisEnabled = true;
			bHasSetFocusPoint = true;
			FHazePointOfInterest Poi;
			Poi.Duration = 1.5f;
			Poi.FocusTarget.Actor = ConnectedFocusActor;
			Poi.bClearOnInput = true;
			Poi.Blend = 1.f;

			Player.ApplySettings(LaserShieldPOISettings, this, EHazeSettingsPriority::Gameplay);

			Player.ApplyPointOfInterest(Poi, this);
		}
	}

	UFUNCTION()
	void OnBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (bHasSetFocusPoint)
			return;

		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if (OverlappingPlayer == nullptr)
			return;

		if (!OverlappingPlayer.HasControl())
			return;

		if (OverlappingPlayer != Game::GetCody())
			return;

		Player = OverlappingPlayer;

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void OnBoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if (OverlappingPlayer == nullptr)
			return;	
		if (Player == nullptr)
			return;

		if (!OverlappingPlayer.HasControl())
			return;

		if (OverlappingPlayer != Game::GetCody())
			return;
		
		Player.ClearSettingsByInstigator(this);

		Player = nullptr;

		bPOIisEnabled = false;

		bHasSetFocusPoint = false;


		SetActorTickEnabled(false);
	}

}

settings LaserShieldPOISettings for UCameraPointOfInterestBehaviourSettings
{
	LaserShieldPOISettings.NoInputThreshold = 0.f; 
	LaserShieldPOISettings.InputClearAngleThreshold = 180.f;
	LaserShieldPOISettings.InputClearWithinAngleDelay = 0.f;
	LaserShieldPOISettings.InputClearDuration = 0.01f;
}