import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class UPlayerFishingWindUpCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingWindUpCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;
	ARodBase RodBase;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::WindingUp)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::WindingUp)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.bCanCancelFishing = false;
		PlayerComp.StoredCastPower = 0.f;

		RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		RodBase.AudioRodWindUpStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RodBase.AudioWindingUpRod(0.f);
		RodBase.AudioRodWindUpEnd();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (WasActionStopped(ActionNames::PrimaryLevelAbility) && HasControl())
		{
			NetSetCasting();
			StoredPower(PlayerComp.StoredCastPower);
		}
		
		RodBase.AudioWindingUpRod(1.f);

		PlayerComp.StoredCastPower = FMath::FInterpConstantTo(PlayerComp.StoredCastPower, PlayerComp.MaxCastPower, DeltaTime, 600.f);
	}

	UFUNCTION(NetFunction)
	void NetSetCasting()
	{
		PlayerComp.FishingState = EFishingState::Casting;
	}

	UFUNCTION(NetFunction)
	void StoredPower(float InputStoredPower)
	{
		PlayerComp.StoredCastPower = InputStoredPower;
	}
}