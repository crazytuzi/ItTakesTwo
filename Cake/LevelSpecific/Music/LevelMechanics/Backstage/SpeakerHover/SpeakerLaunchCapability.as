import Peanuts.Animation.Features.LocomotionFeatureBounce;
import Peanuts.Foghorn.FoghornStatics;
class USpeakerLaunchCapability : UHazeCapability
{
	UPROPERTY()
	TArray<UAnimSequence> CodyAnim;

	UPROPERTY()
	TArray<UAnimSequence> MayAnim;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBankDataAsset;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"LaunchPlayer"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		int RandomIndex = 0;
		if (Player.IsCody())
		{
			RandomIndex = FMath::RandRange(0, CodyAnim.Num() -1);
			FHazePlaySlotAnimationParams Params;
			Params.Animation = CodyAnim[RandomIndex];
			Player.PlaySlotAnimation(Params);
		}
		if (Player.IsMay())
		{
			RandomIndex = FMath::RandRange(0, MayAnim.Num() -1);
			FHazePlaySlotAnimationParams Params;
			Params.Animation = MayAnim[RandomIndex];
			Player.PlaySlotAnimation(Params);
		}

		if(Player.IsCody())
		{
			PlayFoghornVOBankEvent(VOBankDataAsset, n"FoghornDBMusicBackstageSmallSpeakerJumpEffortCody");
		}
		else
		{
			PlayFoghornVOBankEvent(VOBankDataAsset, n"FoghornDBMusicBackstageSmallSpeakerJumpEffortMay");
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}