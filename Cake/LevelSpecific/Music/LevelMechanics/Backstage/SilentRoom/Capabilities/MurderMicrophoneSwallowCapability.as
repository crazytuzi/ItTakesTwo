import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneSwallowCapability : UHazeCapability
{
	FMurderMicrophoneBodyTravel BodyTravel;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	private bool bDoneSwallowing = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Snake.bSwallowPlayer)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bDoneSwallowing = false;
		BodyTravel.StartTravel(Snake, EMurderMicrophoneBodyTravelType::HeadToCore);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TravelSpeed = Snake.CordLengthCurrent / TargetingComp.ChaseRange;
		FVector Location = FVector::ZeroVector;
		bool bDone = false;
		BodyTravel.Travel(Location, bDone, DeltaTime, TravelSpeed);

		const float Radius = 90.0f;
		const float Strength = 40.0f;

		FLinearColor Item0(Location.X, Location.Y, Location.Z, Radius);
		FLinearColor _Strength(Strength, 0, 0, 0);

		Snake.BodyComponent.SetColorParameterValueOnMaterialIndex(0, n"Item0", Item0);
		Snake.BodyComponent.SetColorParameterValueOnMaterialIndex(0, n"Strengths", _Strength);

		if(bDone)
			bDoneSwallowing = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bDoneSwallowing)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Snake.bSwallowPlayer = false;
		FLinearColor Item0(0, 0, 0, 0);
		FLinearColor _Strength(0, 0, 0, 0);
		Snake.BodyComponent.SetColorParameterValueOnMaterialIndex(0, n"Item0", Item0);
		Snake.BodyComponent.SetColorParameterValueOnMaterialIndex(0, n"Strengths", _Strength);
	}

}
