import Cake.LevelSpecific.Shed.Main.MainCogBridge;
class ABridgeCogWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CogWheel;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bActorIsVisualOnly = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY()
	AMainCogBridge BridgeRef;

	UPROPERTY()
	bool BackWardsCog = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetRotation = BridgeRef.RotationPoint.RelativeRotation.Pitch;
		float CurrentRotation = CogWheel.RelativeRotation.Roll;
		
		CurrentRotation = TargetRotation;
		
		// PrintToScreen(""+CurrentRotation);
		
		FRotator NewRotation = FRotator(0.f, 0.f, CurrentRotation * 2.f);

		if (BackWardsCog)
			NewRotation *= -1;
		
		CogWheel.SetRelativeRotation(NewRotation);
	}

}