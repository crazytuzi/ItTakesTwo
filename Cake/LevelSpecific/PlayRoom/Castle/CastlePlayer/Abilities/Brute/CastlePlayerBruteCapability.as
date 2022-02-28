import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastlePlayerCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteSword;

class UCastlePlayerBruteCapability : UCastlePlayerCapability
{
    default CapabilityTags.Add(n"BruteSword");

	UPROPERTY()
	TSubclassOf<ACastleBruteSword> BruteSwordType;
	ACastleBruteSword BruteSword;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastlePlayerCapability::Setup(SetupParams);

		if (BruteSwordType.IsValid())
		{
			BruteSword = Cast<ACastleBruteSword>(SpawnActor(BruteSwordType));

			BruteSword.AttachToActor(OwningPlayer, n"LeftAttach", EAttachmentRule::SnapToTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		BruteSword.DestroyActor();
    }

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if (BruteSword != nullptr)
		{
			BruteSword.HideSword();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		if (BruteSword != nullptr)
		{
			BruteSword.ShowSword();
		}
	}
}