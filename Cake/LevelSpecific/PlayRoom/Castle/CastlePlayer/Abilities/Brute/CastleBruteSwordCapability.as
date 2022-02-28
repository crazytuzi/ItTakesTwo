import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteSword;
import Peanuts.Outlines.Outlines;
import Vino.PlayerHealth.PlayerHealthStatics;

class UCastleBruteSwordCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Castle";
	default CapabilityTags.Add(n"BruteSword");

	AHazePlayerCharacter OwningPlayer;

	UPROPERTY()
	TSubclassOf<ACastleBruteSword> BruteSwordType;
	ACastleBruteSword BruteSword;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		if (BruteSwordType.IsValid())
		{
			BruteSword = Cast<ACastleBruteSword>(SpawnActor(BruteSwordType));
			BruteSword.AttachToActor(OwningPlayer, n"LeftAttach", EAttachmentRule::SnapToTarget);
			AddMeshToPlayerOutline(BruteSword.SwordMesh, OwningPlayer, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsPlayerDead(OwningPlayer))
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(OwningPlayer))
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (BruteSword != nullptr)
		{
			BruteSword.ShowSword();
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{       
		if (BruteSword != nullptr)
		{
			BruteSword.HideSword();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		BruteSword.DestroyActor();
    }
}