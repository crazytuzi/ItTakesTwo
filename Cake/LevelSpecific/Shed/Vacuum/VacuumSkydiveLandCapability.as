import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Components.MovementComponent;

class UVacuumSkydiveLandCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UVacuumVOBank VOBank;

	UPROPERTY()
	TSubclassOf<UVacuumSkydiveLandCapability> CapabilityClass;

	bool bLanded = false;
	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		bActivated = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!bActivated)
        	return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bLanded)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bActivated = true;
		bLanded = false;
	}

	UFUNCTION(BlueprintOverride)
	void BP_ControlPreDeactivation(FCapabilityDeactivationSyncParams InParams, FCapabilityDeactivationSyncParams& OutParams)
	{
		if (bLanded)
			OutParams.AddActionState(n"Landed");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bLanded = DeactivationParams.GetActionState(n"Landed");
		if (bLanded)
		{
			System::SetTimer(this, n"PlayLandBark", 1.f, false);
		}
		else
		{
			Player.RemoveCapability(CapabilityClass);
		}
	}

	UFUNCTION()
	void PlayLandBark()
	{
		if (Player.IsMay())
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumOilPitSkyDiveMayLand");
		else
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumOilPitSkyDiveCodyLand");

		Player.RemoveCapability(CapabilityClass);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.IsGrounded())
			bLanded = true;
	}
}