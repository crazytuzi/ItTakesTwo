import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;
class UShockImpactLocalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GrindShock");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;
	float GetShockedTimer = 0;

	AHazePlayerCharacter Player;

	UPROPERTY()
	UFoghornVOBankDataAssetBase BarksBank;

	UPROPERTY()
	UAnimSequence HitBySparksAnimation_Cody;

	UPROPERTY()
	UAnimSequence HitBySparksAnimation_May;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"HitByElectricShock") && !HasControl())
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetShockedTimer > 1)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
			
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazePlaySlotAnimationParams Params;
		FHazeAnimationDelegate OnAnimEnd;
		Params.Animation = Player.IsCody() ? HitBySparksAnimation_Cody : HitBySparksAnimation_May;
		Params.bLoop = true;

		Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnAnimEnd, Params);
		ConsumeAction(n"HitByElectricShock");

		if(Player.IsCody())
		{
			PlayFoghornVOBankEvent(BarksBank, n"FoghornDBShedMainGrindSectionRespawnElectricityCody");
		}
			
		else
		{
			PlayFoghornVOBankEvent(BarksBank, n"FoghornDBShedMainGrindSectionRespawnElectricityMay");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopAllSlotAnimations();
		GetShockedTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GetShockedTimer += DeltaTime;
	}
}