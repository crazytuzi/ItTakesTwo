import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Cake.LevelSpecific.Music.NightClub.DJStationComponent;
class UDJLightStationCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default CapabilityTags.Add(n"DJLightStation");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	FVector2D RightStickInput;
		
	float PreviousRightStickInput;

	FVector2D LeftStickInput;
		
	float PreviousLeftStickInput;

	bool RightIsPositive = false;

	bool LeftIsPositive = false;

	bool CurrentDirectionDiffFromPrevious = false;
	
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
		if (DJStationComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(DJStationComp.VinylPlayer != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DJStationComp.VinylPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"DJLightStation", DJStationComp.VinylPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		VinylPlayer = Cast<ADJVinylPlayer>(ActivationParams.GetObject(n"DJLightStation"));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		RightStickInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		CalculateStickDirection(RightStickInput.Y, PreviousRightStickInput, LeftStickInput.Y, PreviousLeftStickInput);
		
		PreviousRightStickInput = RightStickInput.Y;
		PreviousLeftStickInput = LeftStickInput.Y;
	}

	void CalculateStickDirection(float RightStickInput, float PreviousRightStickInput, float LeftStickInput, float PreviousLeftStickInput)
	{
		if (RightStickInput > 0.f && !RightIsPositive)
		{
			RightIsPositive = true;
			VinylPlayer.TargetLightTableRate += 15.f;
		}

		if (RightStickInput < 0.f && RightIsPositive)
		{
			RightIsPositive = false;
			VinylPlayer.TargetLightTableRate += 15.f;
		}



		// if (LeftStickInput > 0.f && !LeftIsPositive)
		// {
		// 	LeftIsPositive = true;
		// 	VinylPlayer.LightTableRate += 2.f;
		// }

		// if (LeftStickInput < 0.f && LeftIsPositive)
		// {
		// 	LeftIsPositive = false;
		// 	VinylPlayer.LightTableRate += 2.f;
		// }

		
		
		// float InputSize = Input.Size();
		// FVector2D InputDif = Input - PreviousInput;
		// VinylPlayer.SpinDiffSize += InputDif.Size();
	}
}