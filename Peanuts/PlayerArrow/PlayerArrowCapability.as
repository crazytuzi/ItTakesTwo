import Peanuts.PlayerArrow.PlayerArrow;
import Vino.PlayerHealth.PlayerHealthStatics;
class UPlayerArrowCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PlayerArrow");

	AHazePlayerCharacter Player;
	
	UPROPERTY()
    TSubclassOf<APlayerArrow> PlayerArrowTypeMay;
	UPROPERTY()
    TSubclassOf<APlayerArrow> PlayerArrowTypeCody;

	APlayerArrow PlayerArrow;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		if (PlayerArrowTypeMay.IsValid() && PlayerArrowTypeCody.IsValid())
		{
			TSubclassOf<APlayerArrow> Type = Player.IsMay() ? PlayerArrowTypeMay : PlayerArrowTypeCody;
			PlayerArrow = Cast<APlayerArrow>(SpawnPersistentActor(Type, Owner.ActorLocation, Owner.ActorRotation));
			PlayerArrow.AttachToActor(Owner);
			PlayerArrow.Plane.SetHiddenInGame(true);
		}
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsPlayerDead(Player))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(Player))
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerArrow.Plane.SetHiddenInGame(false);
	}
    
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
 		PlayerArrow.Plane.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (PlayerArrow != nullptr)
			PlayerArrow.DestroyActor();
	}
}