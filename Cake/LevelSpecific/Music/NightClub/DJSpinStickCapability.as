import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Cake.LevelSpecific.Music.NightClub.DJStationComponent;
class UDJSpinStickCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default CapabilityTags.Add(n"DJSpinStick");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	FVector2D RightInput;
		
	FVector2D PreviousRightInput;

	ADJVinylPlayer VinylPlayer;

	UDJStationComponent DJStationComp;
	
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DJStationComp = UDJStationComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(DJStationComp.VinylPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DJStationComp.VinylPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"DJVinylPlayer", DJStationComp.VinylPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		VinylPlayer = Cast<ADJVinylPlayer>(ActivationParams.GetObject(n"DJVinylPlayer"));
		RightInput = FVector2D::ZeroVector;
		PreviousRightInput = FVector2D::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		RightInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		CalculateWheelRotation(RightInput, PreviousRightInput);
		
		PreviousRightInput = RightInput;
	}

	void CalculateWheelRotation(FVector2D Input, FVector2D PreviousInput)
	{
		float InputSize = Input.Size();
		FVector2D InputDif = Input - PreviousInput;
		VinylPlayer.SpinDiffSize += InputDif.Size();
		VinylPlayer.ProgressRate += VinylPlayer.SpinDiffSize;
	}
}