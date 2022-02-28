
import Vino.PlayerHealth.PlayerHealthStatics;

class UShockImpactControlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GrindShock");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;
	bool bShouldDeactivate;
	AHazePlayerCharacter Player;

	UPROPERTY()
	UAnimSequence HitBySparksAnimation_Cody;

	UPROPERTY()
	UAnimSequence HitBySparksAnimation_May;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	UFoghornVOBankDataAssetBase BarksBank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"HitByElectricShock") && HasControl())
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Grinding", this);
		SetMutuallyExclusive(n"GrindShock", true);
		
		if(Player.IsCody())
		{
			PlayFoghornVOBankEvent(BarksBank, n"FoghornDBShedMainGrindSectionRespawnElectricityCody");
		}
			
		else
		{
			PlayFoghornVOBankEvent(BarksBank, n"FoghornDBShedMainGrindSectionRespawnElectricityMay");
		}
		
		KillPlayer(Player, DeathEffect);
		ConsumeAction(n"HitByElectricShock");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"GrindShock", false);
		Player.UnblockCapabilities(n"Grinding", this);
	}
}